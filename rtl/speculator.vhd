--
-- speculator.vhd - Speculator
--
-- Speculator was originally a hardware add-on, constructed using a small
-- RAM chip, some PALs, a couple of latches and delay logic.
-- It provided memory behind Spectrum I/O ports, MTX shadow ports,
-- and a mechanism to convert INTs to NMIs.
--
-- This implementation is largely compatible with the original Speculator.
-- The original partially decoded some of the ports, this fully decodes them.
-- The original didn't handle multiple keyboard rows at once, this does.
--
-- The INT_n signal seems noisy and has been the hardest part to get right.
-- It does appear necessary to use a PULLUP constraint in the .ucf file.
-- It does appear necessary to clean it by looking for 16 consequtive samples
-- at 49MHz - looking for fewer doesn't seem reliable, although I cannot
-- explain this, as you might expect it to still fail with 16, just less often.
--
-- Because of the need to clean INT_n, I'm sure not to recognise it for
-- 325ns, ie: 1.3T, so I cannot properly support immediate NMI mode.
--
-- This implementation supports an extra NMI_enabled2 bit.
-- Turning this on and off does not cause spurious interrupts to occur.
--
-- There are 'extra' Speculator features, must be enabled before use.
--
-- When enabled, we also keep track of T cycles between transitions of
-- the speaker bit, and makes this visible to the Z80.
-- This allows simplistic sound support.
--
-- In addition, we snoop updates to Spectrum screen memory and provide
-- features to allow the Z80 to work out which parts of copy to the VDP.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity speculator is
  port
    (
    extras    : in    std_logic;
    RESET     : in    std_logic; 
    m49       : in    std_logic;
    PHI       : in    std_logic; -- 4MHz
    MREQ_n    : in    std_logic;
    IORQ_n    : in    std_logic;
    RD_n      : in    std_logic;
    WR_n      : in    std_logic;
    iobyte    : in    std_logic_vector( 7 downto 0);
    A         : in    std_logic_vector(15 downto 0);
    DI        : in    std_logic_vector( 7 downto 0);
    DO        : out   std_logic_vector( 7 downto 0);
    DO_valid  : out   std_logic;
    INT_n     : in    std_logic;
    NMI_n     : out   std_logic
    );
end speculator;

architecture behavior of speculator is

  -- simulated Spectrum hardware
  signal kempston : std_logic_vector(7 downto 0) := "00000000";
  signal border   : std_logic_vector(7 downto 0) := "00000000";
  signal fuller   : std_logic_vector(7 downto 0) := "00000000";
  signal printer  : std_logic_vector(7 downto 0) := "00000000";
  type keys_t is array (natural range 0 to 7) of std_logic_vector(7 downto 0);
  signal keys     : keys_t;

  impure function combine_keys( A : std_logic_vector(15 downto 8) )
    return std_logic_vector is
    variable k : std_logic_vector(7 downto 0) := "11111111";
  begin
    for i in 0 to 7 loop
      if A(8+i) = '0' then
        k := k and keys(i);
      end if;
    end loop;
    return k;
  end;

  -- interrupt related
  signal INT_n_samples : std_logic_vector(19 downto 0) := "11111111111111111111";
  signal INT_n_clean   : std_logic := '1';
  signal INT_n_prev    : std_logic := '1';
  signal NMI_enabled   : std_logic := '0';
  signal NMI_immediate : std_logic := '0';
  signal NMI_enabled2  : std_logic := '0';
  signal NMI_n_imm     : std_logic_vector( 7 downto 0) := ( others => '1' );
  signal NMI_n_del     : std_logic_vector(39 downto 0) := ( others => '1' );

  -- sound emulation
  -- count T states between sound bit transitions
  -- human ear can hear between 20Hz and 20000Hz
  -- MTX sound chip can play between 122Hz and 125000Hz
  -- so useful overlap is between 122Hz to 20000Hz
  -- so thats between 244 and 40000 transitions per second
  -- which implies between 16383T and 100T between transitions
  signal t_snd_accum : std_logic_vector(15 downto 0) := (others => '1');
  signal t_snd       : std_logic_vector(15 downto 0) := (others => '1');

  -- time since interrupt detected
  -- UK: 50Hz, 80000T per frame, 192/312 scans active, 30769T is safe
  -- US: 60Hz, 66666T per frame, 192/262 scans active, 17811T is safe (not supported)
  -- empirically I'd say we actually have 100010000000000, ie: 21% of the frame
  -- as an MTX runs at 4MHz and a Spectrum at 3.5MHz, when we use beyond 12.5%
  -- of available CPU for redraw, we're actually slowing the Spectrum down
  signal t_since_int : std_logic_vector(14 downto 0) := (others => '1');
  signal unsafe50hz  : std_logic := '1';

  -- a thing that tracks a byte per character cell
  component speculator_attr
    port
      (
      clk : in  std_logic;
      we  : in  std_logic;
      row : in  std_logic_vector(4 downto 0); -- 0..23
      col : in  std_logic_vector(4 downto 0);
      d   : in  std_logic_vector(7 downto 0);
      q   : out std_logic_vector(7 downto 0)
      );
  end component;

  -- attribute value memory
  signal attr_rd : std_logic;
  signal attr_ck : std_logic;
  signal attr_we : std_logic;
  signal attr_d  : std_logic_vector(7 downto 0);
  signal attr_q  : std_logic_vector(7 downto 0);

  -- a thing that tracks a bit per character cell
  component speculator_cell
    port
      (
      clk    : in  std_logic;
      we     : in  std_logic;
      row_d  : in  std_logic_vector(4 downto 0); -- 0..23
      col_d  : in  std_logic_vector(4 downto 0);
      d      : in  std_logic;
      d_row  : in  std_logic;
      row_q  : in  std_logic_vector(4 downto 0); -- 0..23
      q_row  : out std_logic_vector(0 to 31)
      );
  end component;

  -- updating cell memory
  signal cell_we_pattern    : std_logic := '0';
  signal cell_we_attribs    : std_logic := '0';
  signal cell_we_flashes    : std_logic := '0';
  signal cell_row           : std_logic_vector(4 downto 0); -- 0..23
  signal cell_col           : std_logic_vector(4 downto 0);
  signal cell_d_flashes     : std_logic;
  signal cell_d_row_pattern : std_logic;
  signal cell_d_row_attribs : std_logic;

  -- accessing cell memory
  signal select_attribs : std_logic;
  signal select_flashes : std_logic;
  signal select_row     : std_logic_vector(4 downto 0); -- 0..23
  signal select_rd      : std_logic;
  signal select_copy    : std_logic;
  signal clearing       : std_logic;
  signal cell_q_pattern : std_logic_vector(0 to 31);
  signal cell_q_attribs : std_logic_vector(0 to 31);
  signal cell_q_flashes : std_logic_vector(0 to 31);

  -- scanning for runs
  signal row_bits         : std_logic_vector(0 to 31);
  signal run_pos          : std_logic_vector(4 downto 0);
  signal run_pos_old      : std_logic_vector(4 downto 0);
  signal row_bits_shifted : std_logic_vector(0 to 31);
  signal run_len          : std_logic_vector(5 downto 0);

  function scan_for_1( bits : std_logic_vector(0 to 31) )
    return std_logic_vector is
  begin
    for i in 0 to 31 loop
      if bits(i) = '1' then
        return std_logic_vector( to_unsigned(i,5) );
      end if;
    end loop;
    return "XXXXX"; -- if run doesn't start, doesn't matter what we say
  end;

  function scan_for_0( bits : std_logic_vector(0 to 31) )
    return std_logic_vector is
  begin
    for i in 0 to 31 loop
      if bits(i) = '0' then
        return "0" & std_logic_vector( to_unsigned(i,5) );
      end if;
    end loop;
    return "100000"; -- if run doesn't end, it spans whole width
  end;

  -- exposing information relating to the start of the run
  signal cpu_addr : std_logic_vector(12 downto 0);
  signal vdp_addr : std_logic_vector(13 downto 3);

begin

  U_ATTR : speculator_attr
    port map (
      clk => PHI,
      we  => attr_we,
      row => cell_row,
      col => cell_col,
      d   => attr_d,
      q   => attr_q
      );

  U_ATTRIBS : speculator_cell
    port map (
      clk   => PHI,
      we    => cell_we_attribs,
      row_d => cell_row,
      col_d => cell_col,
      d     => '1',
      d_row => cell_d_row_attribs,
      row_q => select_row,
      q_row => cell_q_attribs
      );

  U_PATTERN : speculator_cell
    port map (
      clk   => PHI,
      we    => cell_we_pattern,
      row_d => cell_row,
      col_d => cell_col,
      d     => '1',
      d_row => cell_d_row_pattern,
      row_q => select_row,
      q_row => cell_q_pattern
      );

  U_FLASHES : speculator_cell
    port map (
      clk   => PHI,
      we    => cell_we_flashes,
      row_d => cell_row,
      col_d => cell_col,
      d     => cell_d_flashes,
      d_row => '1',
      row_q => select_row,
      q_row => cell_q_flashes
      );

  -- clean up the INT_n signal
  process ( m49, INT_n )
  begin
    if rising_edge(m49) then
      if INT_n_samples = "00000000000000000000" and INT_n = '0' then
        INT_n_clean <= '0';
      elsif INT_n_samples = "11111111111111111111" and INT_n = '1' then
        INT_n_clean <= '1';
      end if;
      INT_n_samples <= INT_n_samples(18 downto 0) & INT_n;
    end if;
  end process;

  process ( PHI, RESET )
  begin
    if rising_edge(PHI) then
      if RESET = '1' then
        kempston      <= "00000000";
        fuller        <= "00000000";
        printer       <= "00000000";
        border        <= "00000000";
        INT_n_prev    <= '1';
        NMI_enabled   <= '0';
        NMI_immediate <= '0';
        NMI_enabled2  <= '0';
        NMI_n_imm     <= ( others => '1' );
        NMI_n_del     <= ( others => '1' );
        for i in 0 to 7 loop
          keys(i) <= "11111111";
        end loop;
        cell_we_pattern <= '0';
        cell_we_attribs <= '0';
        cell_we_flashes <= '0';
      else

        -- advance NMI pipeline, unless overridden below
        NMI_n_imm <= '1' & NMI_n_imm( 7 downto 1);
        NMI_n_del <= '1' & NMI_n_del(39 downto 1);

        -- advance time since interrupt detected, unless overridden below
        if t_since_int(14 downto 10) = "10001" then
          unsafe50hz <= '1';
        else
          t_since_int <= t_since_int + 1;
          unsafe50hz <= '0';
        end if;

        -- look for a maskable interrupt
        if INT_n_prev = '1' and INT_n_clean = '0' then
          -- 8T at 4MHz is 2us approx
          NMI_n_imm( 7 downto  0) <= ( others => '0' );
          -- 2us delayed by 8us approx
          NMI_n_del(39 downto 32) <= ( others => '0' );
          NMI_n_del(31 downto  0) <= ( others => '1' );
          t_since_int <= "000000000000000";
        end if;
        INT_n_prev <= INT_n_clean;

        -- keep track of time between sound transitions
        if t_snd_accum = "1111111111111111" then
          -- we've gone so long since an edge, better expose that fact
          t_snd <= "1111111111111111";
        else
          t_snd_accum <= t_snd_accum + 1;
        end if;

        -- not reading or writing attribute value memory, unless overridden
        attr_rd <= '0';
        attr_ck <= '0';
        attr_we <= '0';

        -- not writing to cell memory, unless overridden below
        cell_we_pattern <= '0';
        cell_we_attribs <= '0';
        cell_we_flashes <= '0';

        -- snoop writes to Spectrum screen memory
        if WR_n = '0' and MREQ_n = '0' and ( iobyte = x"80" or iobyte = x"20" ) then
          if A(15 downto 12) = "0100"  or               -- 4000..4fff
             A(15 downto 11) = "01010" then             -- 5000..57ff
            -- writing to screen pattern area
            -- when storing to a pixel at (x,y), A will be comprised as follows
            --   0 1 0  y7 y6  y2 y1 y0  y5 y4 y3  x7 x6 x5 x4 x3
            -- we don't care which pixel in the cell
            cell_row           <= A(12 downto 11) & A(7 downto 5);
            cell_col           <= A(4 downto 0);
            cell_d_row_pattern <= '1';
            cell_we_pattern    <= '1';
          elsif A(15 downto 9) = "0101100"  or          -- 5800..59ff
                A(15 downto 8) = "01011010" then        -- 5a00..5aff
            -- writing to the screen attribute area
            -- when storing to a cell at (x,y), A will be comprised as follows
            --   0 1 0 1 1 0  y4 y3 y2 y1 y0  x4 x3 x2 x1 x0
            -- immmediately record new flash state
            -- initiate read of attribute value to see if changed
            cell_row        <= A(9 downto 5);
            cell_col        <= A(4 downto 0);
            cell_d_flashes  <= DI(7);
            cell_we_flashes <= '1';
            attr_rd         <= '1';
            attr_d          <= DI;
          end if;
        end if;

        if attr_rd = '1' then
          -- in this cycle the memory provides the data on attr_q
          attr_ck <= '1';
        end if;

        if attr_ck = '1' then
          if attr_d /= attr_q then
            -- new attribute is different
            attr_we            <= '1';
            cell_d_row_attribs <= '1';
            cell_we_attribs    <= '1';
          end if;
        end if;

        select_rd   <= '0';
        select_copy <= '0';
        clearing    <= '0';

        -- IO write
        if WR_n = '0' and IORQ_n = '0' then
          case A(7 downto 0) is
            when x"1F" =>
              kempston <= DI;
            when x"7F" =>
              fuller <= DI;
            when x"FB" =>
              printer <= DI;
            when x"FE" =>
              if DI(4) /= border(4) then
                t_snd       <= t_snd_accum;
                t_snd_accum <= "0000000000000000";
              end if;
              border <= DI;
            when x"7E" =>
              for i in 0 to 7 loop
                if A(8+i) = '0' then
                  keys(i) <= DI;
                end if;
              end loop;
            when x"FF" =>
              if NMI_enabled = '0' and DI(0) = '1' then
                -- due to the way the Speculator wired two one-shots in a
                -- 74LS123 together, turning on interrupts causes a single
                -- pulse to leak out, and the code needs this.
                NMI_n_del(39 downto 32) <= ( others => '0' );
                NMI_n_del(31 downto  0) <= ( others => '1' );
              end if;
              NMI_enabled   <= DI(0);
              NMI_immediate <= DI(1);
              NMI_enabled2  <= DI(2);
            when x"B2" =>
              if select_rd = '0' then
                -- select the row
                select_attribs <= DI(7);
                select_flashes <= DI(6);
                select_row     <= DI(4 downto 0);
                select_rd      <= '1';
                  -- stops any following wait start re-selecting same row
                  -- also ensures we pick up row from memory below, later
              end if;
            when x"B3" =>
              if clearing = '0' then
                -- clear leftmost bit
                row_bits( to_integer( unsigned( run_pos_old ) ) ) <= '0';
                clearing <= '1';
                  -- stops any following wait state clearing another bit
              end if;
            when others =>
              -- ignore
          end case;
        end if; -- IO write

        if select_rd = '1' then
          -- in this cycle, data is published to cell_q_pattern etc...
          select_copy <= '1';
        end if;

        if select_copy = '1' then
          cell_row <= select_row;
          if select_attribs = '0' then
            row_bits <= cell_q_pattern;
            cell_we_pattern    <= '1';
            cell_d_row_pattern <= '0';
          else
            if select_flashes = '0' then
              row_bits <= cell_q_attribs;
            else
              row_bits <= cell_q_attribs or cell_q_flashes;
            end if;
            cell_we_attribs    <= '1';
            cell_d_row_attribs <= '0';
          end if;
        end if;

        -- where does the run start
        run_pos <= scan_for_1(row_bits);

        -- a time delayed copy, used for indexing
        run_pos_old <= run_pos;

        -- shift to start of run
        -- as the shift amount is chosen at run time,
        -- presumably this instantiates a huge 32 tap barrel shifter
        row_bits_shifted <= std_logic_vector( shift_left( unsigned(row_bits), to_integer( unsigned( run_pos ) ) ) );

        -- how large is the run?
        run_len <= scan_for_0(row_bits_shifted);

      end if;
    end if;

  end process;

  -- where is the data for the current run, in Z80 memory
  cpu_addr(12 downto 0) <= select_row(4 downto 3) & "000" & select_row(2 downto 0) & run_pos
     when ( select_attribs = '0' )
  else "110" & select_row & run_pos;

  -- where should it be put in VDP memory
  vdp_addr(13 downto 3) <= "0" & select_row & run_pos
    when ( select_attribs = '0' )
  else "1" & select_row & run_pos;

  -- output needs to be "open collector"
  NMI_n <= '0'
    when ( ( NMI_enabled = '1' or NMI_enabled2 = '1' ) and NMI_immediate = '1' and NMI_n_imm(0) = '0' )
  else '0'
    when ( ( NMI_enabled = '1' or NMI_enabled2 = '1' ) and NMI_immediate = '0' and NMI_n_del(0) = '0' )
  else 'Z';

  -- are we supplying data
  DO_valid <= '1'
    when ( RD_n = '0' and IORQ_n = '0' and
      ( A(7 downto 0) = x"1F" or
        A(7 downto 0) = x"7F" or
        A(7 downto 0) = x"FB" or
        A(7 downto 0) = x"7E" or
        A(7 downto 0) = x"FE" or
        ( extras = '1' and
          ( A(7 downto 0) = x"B0" or
            A(7 downto 0) = x"B1" or
            A(7 downto 0) = x"B2" or
            A(7 downto 0) = x"B3" or
            A(7 downto 0) = x"B4" or
            A(7 downto 0) = x"B5" or
            A(7 downto 0) = x"B6" or
            A(7 downto 0) = x"B7"
          )
        )
      )
    )
  else '0';

  -- what value are we supplying
  DO <= kempston
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"1F" )
  else fuller
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"7F" )
  else printer
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"FB" )
  else border
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"7E" )
  else combine_keys( A(15 downto 8) )
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"FE" )
  else t_snd(7 downto 0)
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B0" )
  else t_snd(15 downto 8)
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B1" )
  else "0000000" & unsafe50hz
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B2" )
  else "00" & run_len
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B3" )
  else cpu_addr(7 downto 0)
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B4" )
  else "010" & cpu_addr(12 downto 8)
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B5" )
  else vdp_addr(7 downto 3) & "000"
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B6" )
  else "01" & vdp_addr(13 downto 8)
    when ( RD_n = '0' and IORQ_n = '0' and A(7 downto 0) = x"B7" )

  else "XXXXXXXX";

end behavior;

