--
-- speculator_attr.vhd - Cell attribute memory, dual port RAM
--
-- Synchronous write and read interface.
-- We do it this way so as to be able to exploit distributed memory.
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity speculator_attr is
  port
    (
    clk : in  std_logic;
    we  : in  std_logic;
    row : in  std_logic_vector(4 downto 0); -- 0..23
    col : in  std_logic_vector(4 downto 0);
    d   : in  std_logic_vector(7 downto 0);
    q   : out std_logic_vector(7 downto 0)
    );
end speculator_attr;

architecture behavior of speculator_attr is

  type attr_type is array (0 to 24*32-1) of std_logic_vector(7 downto 0);
  signal attr : attr_type;

begin

  process ( clk )
  begin
    if rising_edge(clk) then
      if we = '1' then
        -- bizarre, Xilinx ISE doesn't seem to know that a
        -- std_logic_vector & std_logic_vector -> std_logic_vector
        -- I have to expliclity tell it using the std_logic_vector' prefix
        attr( to_integer( unsigned( std_logic_vector'(row&col) ) ) ) <= d;
      end if;
      q <= attr( to_integer( unsigned( std_logic_vector'(row&col) ) ) );
    end if;
  end process;

end behavior;

