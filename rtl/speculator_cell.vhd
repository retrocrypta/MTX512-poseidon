--
-- speculator_cell.vhd - Cell memory, dual port RAM
--
-- Synchronous write interface, bit by bit.
-- Synchronous read interface, all bits in a row at once.
--
-- We do it this way so as to be able to exploit distributed memory
-- in the FPGA, rather than end up instantiating over 2000 flip-flops.
-- Distributed memory can have synchronous write and asynchronous read.
-- Synchronous read can be faked during synthesis up by latching the output.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity speculator_cell is
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
end speculator_cell;

architecture behavior of speculator_cell is

  type cell_type is array (0 to 23) of std_logic_vector(0 to 31);
  signal cell : cell_type;
  signal d_new : std_logic_vector(0 to 31);

begin

  process ( row_d, col_d, cell, d, d_row )
    variable d_old : std_logic_vector(0 to 31);
  begin
    d_old := cell( to_integer( unsigned( row_d ) ) );
    for i in 0 to 31 loop
      if d_row = '0' then
        d_new(i) <= '0';
      elsif std_logic_vector( to_unsigned( i, 5 ) ) = col_d then
        d_new(i) <= d;
      else
        d_new(i) <= d_old(i);
      end if;
    end loop;
  end process;

  process ( clk )
  begin
    if rising_edge(clk) then
      if we = '1' then
        cell( to_integer( unsigned( row_d ) ) ) <= d_new;
      end if;
      q_row <= cell( to_integer( unsigned( row_q ) ) );
    end if;
  end process;

end behavior;

