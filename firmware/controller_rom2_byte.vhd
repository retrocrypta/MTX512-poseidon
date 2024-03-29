
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity controller_rom2 is
generic
	(
		ADDR_WIDTH : integer := 15 -- Specify your actual ROM size to save LEs and unnecessary block RAM usage.
	);
port (
	clk : in std_logic;
	reset_n : in std_logic := '1';
	addr : in std_logic_vector(ADDR_WIDTH-1 downto 0);
	q : out std_logic_vector(31 downto 0);
	-- Allow writes - defaults supplied to simplify projects that don't need to write.
	d : in std_logic_vector(31 downto 0) := X"00000000";
	we : in std_logic := '0';
	bytesel : in std_logic_vector(3 downto 0) := "1111"
);
end entity;

architecture rtl of controller_rom2 is

	signal addr1 : integer range 0 to 2**ADDR_WIDTH-1;

	--  build up 2D array to hold the memory
	type word_t is array (0 to 3) of std_logic_vector(7 downto 0);
	type ram_t is array (0 to 2 ** ADDR_WIDTH - 1) of word_t;

	signal ram : ram_t:=
	(

     0 => (x"00",x"60",x"60",x"00"),
     1 => (x"60",x"40",x"00",x"00"),
     2 => (x"06",x"0c",x"18",x"30"),
     3 => (x"3e",x"00",x"01",x"03"),
     4 => (x"7f",x"4d",x"59",x"7f"),
     5 => (x"04",x"00",x"00",x"3e"),
     6 => (x"00",x"7f",x"7f",x"06"),
     7 => (x"42",x"00",x"00",x"00"),
     8 => (x"4f",x"59",x"71",x"63"),
     9 => (x"22",x"00",x"00",x"46"),
    10 => (x"7f",x"49",x"49",x"63"),
    11 => (x"1c",x"18",x"00",x"36"),
    12 => (x"7f",x"7f",x"13",x"16"),
    13 => (x"27",x"00",x"00",x"10"),
    14 => (x"7d",x"45",x"45",x"67"),
    15 => (x"3c",x"00",x"00",x"39"),
    16 => (x"79",x"49",x"4b",x"7e"),
    17 => (x"01",x"00",x"00",x"30"),
    18 => (x"0f",x"79",x"71",x"01"),
    19 => (x"36",x"00",x"00",x"07"),
    20 => (x"7f",x"49",x"49",x"7f"),
    21 => (x"06",x"00",x"00",x"36"),
    22 => (x"3f",x"69",x"49",x"4f"),
    23 => (x"00",x"00",x"00",x"1e"),
    24 => (x"00",x"66",x"66",x"00"),
    25 => (x"00",x"00",x"00",x"00"),
    26 => (x"00",x"66",x"e6",x"80"),
    27 => (x"08",x"00",x"00",x"00"),
    28 => (x"22",x"14",x"14",x"08"),
    29 => (x"14",x"00",x"00",x"22"),
    30 => (x"14",x"14",x"14",x"14"),
    31 => (x"22",x"00",x"00",x"14"),
    32 => (x"08",x"14",x"14",x"22"),
    33 => (x"02",x"00",x"00",x"08"),
    34 => (x"0f",x"59",x"51",x"03"),
    35 => (x"7f",x"3e",x"00",x"06"),
    36 => (x"1f",x"55",x"5d",x"41"),
    37 => (x"7e",x"00",x"00",x"1e"),
    38 => (x"7f",x"09",x"09",x"7f"),
    39 => (x"7f",x"00",x"00",x"7e"),
    40 => (x"7f",x"49",x"49",x"7f"),
    41 => (x"1c",x"00",x"00",x"36"),
    42 => (x"41",x"41",x"63",x"3e"),
    43 => (x"7f",x"00",x"00",x"41"),
    44 => (x"3e",x"63",x"41",x"7f"),
    45 => (x"7f",x"00",x"00",x"1c"),
    46 => (x"41",x"49",x"49",x"7f"),
    47 => (x"7f",x"00",x"00",x"41"),
    48 => (x"01",x"09",x"09",x"7f"),
    49 => (x"3e",x"00",x"00",x"01"),
    50 => (x"7b",x"49",x"41",x"7f"),
    51 => (x"7f",x"00",x"00",x"7a"),
    52 => (x"7f",x"08",x"08",x"7f"),
    53 => (x"00",x"00",x"00",x"7f"),
    54 => (x"41",x"7f",x"7f",x"41"),
    55 => (x"20",x"00",x"00",x"00"),
    56 => (x"7f",x"40",x"40",x"60"),
    57 => (x"7f",x"7f",x"00",x"3f"),
    58 => (x"63",x"36",x"1c",x"08"),
    59 => (x"7f",x"00",x"00",x"41"),
    60 => (x"40",x"40",x"40",x"7f"),
    61 => (x"7f",x"7f",x"00",x"40"),
    62 => (x"7f",x"06",x"0c",x"06"),
    63 => (x"7f",x"7f",x"00",x"7f"),
    64 => (x"7f",x"18",x"0c",x"06"),
    65 => (x"3e",x"00",x"00",x"7f"),
    66 => (x"7f",x"41",x"41",x"7f"),
    67 => (x"7f",x"00",x"00",x"3e"),
    68 => (x"0f",x"09",x"09",x"7f"),
    69 => (x"7f",x"3e",x"00",x"06"),
    70 => (x"7e",x"7f",x"61",x"41"),
    71 => (x"7f",x"00",x"00",x"40"),
    72 => (x"7f",x"19",x"09",x"7f"),
    73 => (x"26",x"00",x"00",x"66"),
    74 => (x"7b",x"59",x"4d",x"6f"),
    75 => (x"01",x"00",x"00",x"32"),
    76 => (x"01",x"7f",x"7f",x"01"),
    77 => (x"3f",x"00",x"00",x"01"),
    78 => (x"7f",x"40",x"40",x"7f"),
    79 => (x"0f",x"00",x"00",x"3f"),
    80 => (x"3f",x"70",x"70",x"3f"),
    81 => (x"7f",x"7f",x"00",x"0f"),
    82 => (x"7f",x"30",x"18",x"30"),
    83 => (x"63",x"41",x"00",x"7f"),
    84 => (x"36",x"1c",x"1c",x"36"),
    85 => (x"03",x"01",x"41",x"63"),
    86 => (x"06",x"7c",x"7c",x"06"),
    87 => (x"71",x"61",x"01",x"03"),
    88 => (x"43",x"47",x"4d",x"59"),
    89 => (x"00",x"00",x"00",x"41"),
    90 => (x"41",x"41",x"7f",x"7f"),
    91 => (x"03",x"01",x"00",x"00"),
    92 => (x"30",x"18",x"0c",x"06"),
    93 => (x"00",x"00",x"40",x"60"),
    94 => (x"7f",x"7f",x"41",x"41"),
    95 => (x"0c",x"08",x"00",x"00"),
    96 => (x"0c",x"06",x"03",x"06"),
    97 => (x"80",x"80",x"00",x"08"),
    98 => (x"80",x"80",x"80",x"80"),
    99 => (x"00",x"00",x"00",x"80"),
   100 => (x"04",x"07",x"03",x"00"),
   101 => (x"20",x"00",x"00",x"00"),
   102 => (x"7c",x"54",x"54",x"74"),
   103 => (x"7f",x"00",x"00",x"78"),
   104 => (x"7c",x"44",x"44",x"7f"),
   105 => (x"38",x"00",x"00",x"38"),
   106 => (x"44",x"44",x"44",x"7c"),
   107 => (x"38",x"00",x"00",x"00"),
   108 => (x"7f",x"44",x"44",x"7c"),
   109 => (x"38",x"00",x"00",x"7f"),
   110 => (x"5c",x"54",x"54",x"7c"),
   111 => (x"04",x"00",x"00",x"18"),
   112 => (x"05",x"05",x"7f",x"7e"),
   113 => (x"18",x"00",x"00",x"00"),
   114 => (x"fc",x"a4",x"a4",x"bc"),
   115 => (x"7f",x"00",x"00",x"7c"),
   116 => (x"7c",x"04",x"04",x"7f"),
   117 => (x"00",x"00",x"00",x"78"),
   118 => (x"40",x"7d",x"3d",x"00"),
   119 => (x"80",x"00",x"00",x"00"),
   120 => (x"7d",x"fd",x"80",x"80"),
   121 => (x"7f",x"00",x"00",x"00"),
   122 => (x"6c",x"38",x"10",x"7f"),
   123 => (x"00",x"00",x"00",x"44"),
   124 => (x"40",x"7f",x"3f",x"00"),
   125 => (x"7c",x"7c",x"00",x"00"),
   126 => (x"7c",x"0c",x"18",x"0c"),
   127 => (x"7c",x"00",x"00",x"78"),
   128 => (x"7c",x"04",x"04",x"7c"),
   129 => (x"38",x"00",x"00",x"78"),
   130 => (x"7c",x"44",x"44",x"7c"),
   131 => (x"fc",x"00",x"00",x"38"),
   132 => (x"3c",x"24",x"24",x"fc"),
   133 => (x"18",x"00",x"00",x"18"),
   134 => (x"fc",x"24",x"24",x"3c"),
   135 => (x"7c",x"00",x"00",x"fc"),
   136 => (x"0c",x"04",x"04",x"7c"),
   137 => (x"48",x"00",x"00",x"08"),
   138 => (x"74",x"54",x"54",x"5c"),
   139 => (x"04",x"00",x"00",x"20"),
   140 => (x"44",x"44",x"7f",x"3f"),
   141 => (x"3c",x"00",x"00",x"00"),
   142 => (x"7c",x"40",x"40",x"7c"),
   143 => (x"1c",x"00",x"00",x"7c"),
   144 => (x"3c",x"60",x"60",x"3c"),
   145 => (x"7c",x"3c",x"00",x"1c"),
   146 => (x"7c",x"60",x"30",x"60"),
   147 => (x"6c",x"44",x"00",x"3c"),
   148 => (x"6c",x"38",x"10",x"38"),
   149 => (x"1c",x"00",x"00",x"44"),
   150 => (x"3c",x"60",x"e0",x"bc"),
   151 => (x"44",x"00",x"00",x"1c"),
   152 => (x"4c",x"5c",x"74",x"64"),
   153 => (x"08",x"00",x"00",x"44"),
   154 => (x"41",x"77",x"3e",x"08"),
   155 => (x"00",x"00",x"00",x"41"),
   156 => (x"00",x"7f",x"7f",x"00"),
   157 => (x"41",x"00",x"00",x"00"),
   158 => (x"08",x"3e",x"77",x"41"),
   159 => (x"01",x"02",x"00",x"08"),
   160 => (x"02",x"02",x"03",x"01"),
   161 => (x"7f",x"7f",x"00",x"01"),
   162 => (x"7f",x"7f",x"7f",x"7f"),
   163 => (x"08",x"08",x"00",x"7f"),
   164 => (x"3e",x"3e",x"1c",x"1c"),
   165 => (x"7f",x"7f",x"7f",x"7f"),
   166 => (x"1c",x"1c",x"3e",x"3e"),
   167 => (x"10",x"00",x"08",x"08"),
   168 => (x"18",x"7c",x"7c",x"18"),
   169 => (x"10",x"00",x"00",x"10"),
   170 => (x"30",x"7c",x"7c",x"30"),
   171 => (x"30",x"10",x"00",x"10"),
   172 => (x"1e",x"78",x"60",x"60"),
   173 => (x"66",x"42",x"00",x"06"),
   174 => (x"66",x"3c",x"18",x"3c"),
   175 => (x"38",x"78",x"00",x"42"),
   176 => (x"6c",x"c6",x"c2",x"6a"),
   177 => (x"00",x"60",x"00",x"38"),
   178 => (x"00",x"00",x"60",x"00"),
   179 => (x"5e",x"0e",x"00",x"60"),
   180 => (x"0e",x"5d",x"5c",x"5b"),
   181 => (x"c2",x"4c",x"71",x"1e"),
   182 => (x"4d",x"bf",x"e1",x"f7"),
   183 => (x"1e",x"c0",x"4b",x"c0"),
   184 => (x"c7",x"02",x"ab",x"74"),
   185 => (x"48",x"a6",x"c4",x"87"),
   186 => (x"87",x"c5",x"78",x"c0"),
   187 => (x"c1",x"48",x"a6",x"c4"),
   188 => (x"1e",x"66",x"c4",x"78"),
   189 => (x"df",x"ee",x"49",x"73"),
   190 => (x"c0",x"86",x"c8",x"87"),
   191 => (x"ef",x"ef",x"49",x"e0"),
   192 => (x"4a",x"a5",x"c4",x"87"),
   193 => (x"f0",x"f0",x"49",x"6a"),
   194 => (x"87",x"c6",x"f1",x"87"),
   195 => (x"83",x"c1",x"85",x"cb"),
   196 => (x"04",x"ab",x"b7",x"c8"),
   197 => (x"26",x"87",x"c7",x"ff"),
   198 => (x"4c",x"26",x"4d",x"26"),
   199 => (x"4f",x"26",x"4b",x"26"),
   200 => (x"c2",x"4a",x"71",x"1e"),
   201 => (x"c2",x"5a",x"e5",x"f7"),
   202 => (x"c7",x"48",x"e5",x"f7"),
   203 => (x"dd",x"fe",x"49",x"78"),
   204 => (x"1e",x"4f",x"26",x"87"),
   205 => (x"4a",x"71",x"1e",x"73"),
   206 => (x"03",x"aa",x"b7",x"c0"),
   207 => (x"db",x"c2",x"87",x"d3"),
   208 => (x"c4",x"05",x"bf",x"cc"),
   209 => (x"c2",x"4b",x"c1",x"87"),
   210 => (x"c2",x"4b",x"c0",x"87"),
   211 => (x"c4",x"5b",x"d0",x"db"),
   212 => (x"d0",x"db",x"c2",x"87"),
   213 => (x"cc",x"db",x"c2",x"5a"),
   214 => (x"9a",x"c1",x"4a",x"bf"),
   215 => (x"49",x"a2",x"c0",x"c1"),
   216 => (x"fc",x"87",x"e8",x"ec"),
   217 => (x"cc",x"db",x"c2",x"48"),
   218 => (x"ef",x"fe",x"78",x"bf"),
   219 => (x"4a",x"71",x"1e",x"87"),
   220 => (x"72",x"1e",x"66",x"c4"),
   221 => (x"87",x"ee",x"e9",x"49"),
   222 => (x"1e",x"4f",x"26",x"26"),
   223 => (x"bf",x"cc",x"db",x"c2"),
   224 => (x"87",x"f3",x"e5",x"49"),
   225 => (x"48",x"d9",x"f7",x"c2"),
   226 => (x"c2",x"78",x"bf",x"e8"),
   227 => (x"ec",x"48",x"d5",x"f7"),
   228 => (x"f7",x"c2",x"78",x"bf"),
   229 => (x"49",x"4a",x"bf",x"d9"),
   230 => (x"c8",x"99",x"ff",x"c3"),
   231 => (x"48",x"72",x"2a",x"b7"),
   232 => (x"f7",x"c2",x"b0",x"71"),
   233 => (x"4f",x"26",x"58",x"e1"),
   234 => (x"5c",x"5b",x"5e",x"0e"),
   235 => (x"4b",x"71",x"0e",x"5d"),
   236 => (x"c2",x"87",x"c8",x"ff"),
   237 => (x"c0",x"48",x"d4",x"f7"),
   238 => (x"e5",x"49",x"73",x"50"),
   239 => (x"49",x"70",x"87",x"d9"),
   240 => (x"cb",x"9c",x"c2",x"4c"),
   241 => (x"cb",x"cc",x"49",x"ee"),
   242 => (x"4d",x"49",x"70",x"87"),
   243 => (x"97",x"d4",x"f7",x"c2"),
   244 => (x"e2",x"c1",x"05",x"bf"),
   245 => (x"49",x"66",x"d0",x"87"),
   246 => (x"bf",x"dd",x"f7",x"c2"),
   247 => (x"87",x"d6",x"05",x"99"),
   248 => (x"c2",x"49",x"66",x"d4"),
   249 => (x"99",x"bf",x"d5",x"f7"),
   250 => (x"73",x"87",x"cb",x"05"),
   251 => (x"87",x"e7",x"e4",x"49"),
   252 => (x"c1",x"02",x"98",x"70"),
   253 => (x"4c",x"c1",x"87",x"c1"),
   254 => (x"75",x"87",x"c0",x"fe"),
   255 => (x"87",x"e0",x"cb",x"49"),
   256 => (x"c6",x"02",x"98",x"70"),
   257 => (x"d4",x"f7",x"c2",x"87"),
   258 => (x"c2",x"50",x"c1",x"48"),
   259 => (x"bf",x"97",x"d4",x"f7"),
   260 => (x"87",x"e3",x"c0",x"05"),
   261 => (x"bf",x"dd",x"f7",x"c2"),
   262 => (x"99",x"66",x"d0",x"49"),
   263 => (x"87",x"d6",x"ff",x"05"),
   264 => (x"bf",x"d5",x"f7",x"c2"),
   265 => (x"99",x"66",x"d4",x"49"),
   266 => (x"87",x"ca",x"ff",x"05"),
   267 => (x"e6",x"e3",x"49",x"73"),
   268 => (x"05",x"98",x"70",x"87"),
   269 => (x"74",x"87",x"ff",x"fe"),
   270 => (x"87",x"dc",x"fb",x"48"),
   271 => (x"5c",x"5b",x"5e",x"0e"),
   272 => (x"86",x"f4",x"0e",x"5d"),
   273 => (x"ec",x"4c",x"4d",x"c0"),
   274 => (x"a6",x"c4",x"7e",x"bf"),
   275 => (x"e1",x"f7",x"c2",x"48"),
   276 => (x"1e",x"c1",x"78",x"bf"),
   277 => (x"49",x"c7",x"1e",x"c0"),
   278 => (x"c8",x"87",x"cd",x"fd"),
   279 => (x"02",x"98",x"70",x"86"),
   280 => (x"49",x"ff",x"87",x"cd"),
   281 => (x"c1",x"87",x"cc",x"fb"),
   282 => (x"ea",x"e2",x"49",x"da"),
   283 => (x"c2",x"4d",x"c1",x"87"),
   284 => (x"bf",x"97",x"d4",x"f7"),
   285 => (x"d1",x"87",x"c3",x"02"),
   286 => (x"f7",x"c2",x"87",x"c9"),
   287 => (x"c2",x"4b",x"bf",x"d9"),
   288 => (x"05",x"bf",x"cc",x"db"),
   289 => (x"c4",x"87",x"d9",x"c1"),
   290 => (x"c0",x"c8",x"48",x"a6"),
   291 => (x"da",x"c2",x"78",x"c0"),
   292 => (x"97",x"6e",x"7e",x"f8"),
   293 => (x"48",x"6e",x"49",x"bf"),
   294 => (x"7e",x"70",x"80",x"c1"),
   295 => (x"87",x"f7",x"e1",x"71"),
   296 => (x"c3",x"02",x"98",x"70"),
   297 => (x"b3",x"66",x"c4",x"87"),
   298 => (x"c1",x"48",x"66",x"c4"),
   299 => (x"a6",x"c8",x"28",x"b7"),
   300 => (x"05",x"98",x"70",x"58"),
   301 => (x"c3",x"87",x"db",x"ff"),
   302 => (x"da",x"e1",x"49",x"fd"),
   303 => (x"49",x"fa",x"c3",x"87"),
   304 => (x"73",x"87",x"d4",x"e1"),
   305 => (x"99",x"ff",x"c3",x"49"),
   306 => (x"49",x"c0",x"1e",x"71"),
   307 => (x"73",x"87",x"de",x"fa"),
   308 => (x"29",x"b7",x"c8",x"49"),
   309 => (x"49",x"c1",x"1e",x"71"),
   310 => (x"c8",x"87",x"d2",x"fa"),
   311 => (x"87",x"c1",x"c6",x"86"),
   312 => (x"bf",x"dd",x"f7",x"c2"),
   313 => (x"dd",x"02",x"9b",x"4b"),
   314 => (x"c8",x"db",x"c2",x"87"),
   315 => (x"ef",x"c7",x"49",x"bf"),
   316 => (x"05",x"98",x"70",x"87"),
   317 => (x"4b",x"c0",x"87",x"c4"),
   318 => (x"e0",x"c2",x"87",x"d2"),
   319 => (x"87",x"d4",x"c7",x"49"),
   320 => (x"58",x"cc",x"db",x"c2"),
   321 => (x"db",x"c2",x"87",x"c6"),
   322 => (x"78",x"c0",x"48",x"c8"),
   323 => (x"99",x"c2",x"49",x"73"),
   324 => (x"c3",x"87",x"ce",x"05"),
   325 => (x"df",x"ff",x"49",x"eb"),
   326 => (x"49",x"70",x"87",x"fd"),
   327 => (x"c2",x"02",x"99",x"c2"),
   328 => (x"73",x"4c",x"fb",x"87"),
   329 => (x"05",x"99",x"c1",x"49"),
   330 => (x"f4",x"c3",x"87",x"ce"),
   331 => (x"e6",x"df",x"ff",x"49"),
   332 => (x"c2",x"49",x"70",x"87"),
   333 => (x"87",x"c2",x"02",x"99"),
   334 => (x"49",x"73",x"4c",x"fa"),
   335 => (x"ce",x"05",x"99",x"c8"),
   336 => (x"49",x"f5",x"c3",x"87"),
   337 => (x"87",x"cf",x"df",x"ff"),
   338 => (x"99",x"c2",x"49",x"70"),
   339 => (x"c2",x"87",x"d5",x"02"),
   340 => (x"02",x"bf",x"e5",x"f7"),
   341 => (x"c1",x"48",x"87",x"ca"),
   342 => (x"e9",x"f7",x"c2",x"88"),
   343 => (x"87",x"c2",x"c0",x"58"),
   344 => (x"4d",x"c1",x"4c",x"ff"),
   345 => (x"99",x"c4",x"49",x"73"),
   346 => (x"c3",x"87",x"ce",x"05"),
   347 => (x"de",x"ff",x"49",x"f2"),
   348 => (x"49",x"70",x"87",x"e5"),
   349 => (x"dc",x"02",x"99",x"c2"),
   350 => (x"e5",x"f7",x"c2",x"87"),
   351 => (x"c7",x"48",x"7e",x"bf"),
   352 => (x"c0",x"03",x"a8",x"b7"),
   353 => (x"48",x"6e",x"87",x"cb"),
   354 => (x"f7",x"c2",x"80",x"c1"),
   355 => (x"c2",x"c0",x"58",x"e9"),
   356 => (x"c1",x"4c",x"fe",x"87"),
   357 => (x"49",x"fd",x"c3",x"4d"),
   358 => (x"87",x"fb",x"dd",x"ff"),
   359 => (x"99",x"c2",x"49",x"70"),
   360 => (x"87",x"d5",x"c0",x"02"),
   361 => (x"bf",x"e5",x"f7",x"c2"),
   362 => (x"87",x"c9",x"c0",x"02"),
   363 => (x"48",x"e5",x"f7",x"c2"),
   364 => (x"c2",x"c0",x"78",x"c0"),
   365 => (x"c1",x"4c",x"fd",x"87"),
   366 => (x"49",x"fa",x"c3",x"4d"),
   367 => (x"87",x"d7",x"dd",x"ff"),
   368 => (x"99",x"c2",x"49",x"70"),
   369 => (x"87",x"d9",x"c0",x"02"),
   370 => (x"bf",x"e5",x"f7",x"c2"),
   371 => (x"a8",x"b7",x"c7",x"48"),
   372 => (x"87",x"c9",x"c0",x"03"),
   373 => (x"48",x"e5",x"f7",x"c2"),
   374 => (x"c2",x"c0",x"78",x"c7"),
   375 => (x"c1",x"4c",x"fc",x"87"),
   376 => (x"ac",x"b7",x"c0",x"4d"),
   377 => (x"87",x"d1",x"c0",x"03"),
   378 => (x"c1",x"4a",x"66",x"c4"),
   379 => (x"02",x"6a",x"82",x"d8"),
   380 => (x"6a",x"87",x"c6",x"c0"),
   381 => (x"73",x"49",x"74",x"4b"),
   382 => (x"c3",x"1e",x"c0",x"0f"),
   383 => (x"da",x"c1",x"1e",x"f0"),
   384 => (x"87",x"e4",x"f6",x"49"),
   385 => (x"98",x"70",x"86",x"c8"),
   386 => (x"87",x"e2",x"c0",x"02"),
   387 => (x"c2",x"48",x"a6",x"c8"),
   388 => (x"78",x"bf",x"e5",x"f7"),
   389 => (x"cb",x"49",x"66",x"c8"),
   390 => (x"48",x"66",x"c4",x"91"),
   391 => (x"7e",x"70",x"80",x"71"),
   392 => (x"c0",x"02",x"bf",x"6e"),
   393 => (x"bf",x"6e",x"87",x"c8"),
   394 => (x"49",x"66",x"c8",x"4b"),
   395 => (x"9d",x"75",x"0f",x"73"),
   396 => (x"87",x"c8",x"c0",x"02"),
   397 => (x"bf",x"e5",x"f7",x"c2"),
   398 => (x"87",x"d2",x"f2",x"49"),
   399 => (x"bf",x"d0",x"db",x"c2"),
   400 => (x"87",x"dd",x"c0",x"02"),
   401 => (x"87",x"d8",x"c2",x"49"),
   402 => (x"c0",x"02",x"98",x"70"),
   403 => (x"f7",x"c2",x"87",x"d3"),
   404 => (x"f1",x"49",x"bf",x"e5"),
   405 => (x"49",x"c0",x"87",x"f8"),
   406 => (x"c2",x"87",x"d8",x"f3"),
   407 => (x"c0",x"48",x"d0",x"db"),
   408 => (x"f2",x"8e",x"f4",x"78"),
   409 => (x"5e",x"0e",x"87",x"f2"),
   410 => (x"0e",x"5d",x"5c",x"5b"),
   411 => (x"c2",x"4c",x"71",x"1e"),
   412 => (x"49",x"bf",x"e1",x"f7"),
   413 => (x"4d",x"a1",x"cd",x"c1"),
   414 => (x"69",x"81",x"d1",x"c1"),
   415 => (x"02",x"9c",x"74",x"7e"),
   416 => (x"a5",x"c4",x"87",x"cf"),
   417 => (x"c2",x"7b",x"74",x"4b"),
   418 => (x"49",x"bf",x"e1",x"f7"),
   419 => (x"6e",x"87",x"d1",x"f2"),
   420 => (x"05",x"9c",x"74",x"7b"),
   421 => (x"4b",x"c0",x"87",x"c4"),
   422 => (x"4b",x"c1",x"87",x"c2"),
   423 => (x"d2",x"f2",x"49",x"73"),
   424 => (x"02",x"66",x"d4",x"87"),
   425 => (x"c0",x"49",x"87",x"c8"),
   426 => (x"4a",x"70",x"87",x"ea"),
   427 => (x"4a",x"c0",x"87",x"c2"),
   428 => (x"5a",x"d4",x"db",x"c2"),
   429 => (x"87",x"e0",x"f1",x"26"),
   430 => (x"14",x"11",x"12",x"58"),
   431 => (x"23",x"1c",x"1b",x"1d"),
   432 => (x"94",x"91",x"59",x"5a"),
   433 => (x"f4",x"eb",x"f2",x"f5"),
   434 => (x"00",x"00",x"00",x"00"),
   435 => (x"00",x"00",x"00",x"00"),
   436 => (x"00",x"00",x"00",x"00"),
   437 => (x"ff",x"4a",x"71",x"1e"),
   438 => (x"72",x"49",x"bf",x"c8"),
   439 => (x"4f",x"26",x"48",x"a1"),
   440 => (x"bf",x"c8",x"ff",x"1e"),
   441 => (x"c0",x"c0",x"fe",x"89"),
   442 => (x"a9",x"c0",x"c0",x"c0"),
   443 => (x"c0",x"87",x"c4",x"01"),
   444 => (x"c1",x"87",x"c2",x"4a"),
   445 => (x"26",x"48",x"72",x"4a"),
   446 => (x"5b",x"5e",x"0e",x"4f"),
   447 => (x"71",x"0e",x"5d",x"5c"),
   448 => (x"4c",x"d4",x"ff",x"4b"),
   449 => (x"c0",x"48",x"66",x"d0"),
   450 => (x"ff",x"49",x"d6",x"78"),
   451 => (x"c3",x"87",x"c0",x"da"),
   452 => (x"49",x"6c",x"7c",x"ff"),
   453 => (x"71",x"99",x"ff",x"c3"),
   454 => (x"f0",x"c3",x"49",x"4d"),
   455 => (x"a9",x"e0",x"c1",x"99"),
   456 => (x"c3",x"87",x"cb",x"05"),
   457 => (x"48",x"6c",x"7c",x"ff"),
   458 => (x"66",x"d0",x"98",x"c3"),
   459 => (x"ff",x"c3",x"78",x"08"),
   460 => (x"49",x"4a",x"6c",x"7c"),
   461 => (x"ff",x"c3",x"31",x"c8"),
   462 => (x"71",x"4a",x"6c",x"7c"),
   463 => (x"c8",x"49",x"72",x"b2"),
   464 => (x"7c",x"ff",x"c3",x"31"),
   465 => (x"b2",x"71",x"4a",x"6c"),
   466 => (x"31",x"c8",x"49",x"72"),
   467 => (x"6c",x"7c",x"ff",x"c3"),
   468 => (x"ff",x"b2",x"71",x"4a"),
   469 => (x"e0",x"c0",x"48",x"d0"),
   470 => (x"02",x"9b",x"73",x"78"),
   471 => (x"7b",x"72",x"87",x"c2"),
   472 => (x"4d",x"26",x"48",x"75"),
   473 => (x"4b",x"26",x"4c",x"26"),
   474 => (x"26",x"1e",x"4f",x"26"),
   475 => (x"5b",x"5e",x"0e",x"4f"),
   476 => (x"86",x"f8",x"0e",x"5c"),
   477 => (x"a6",x"c8",x"1e",x"76"),
   478 => (x"87",x"fd",x"fd",x"49"),
   479 => (x"4b",x"70",x"86",x"c4"),
   480 => (x"a8",x"c4",x"48",x"6e"),
   481 => (x"87",x"f4",x"c2",x"03"),
   482 => (x"f0",x"c3",x"4a",x"73"),
   483 => (x"aa",x"d0",x"c1",x"9a"),
   484 => (x"c1",x"87",x"c7",x"02"),
   485 => (x"c2",x"05",x"aa",x"e0"),
   486 => (x"49",x"73",x"87",x"e2"),
   487 => (x"c3",x"02",x"99",x"c8"),
   488 => (x"87",x"c6",x"ff",x"87"),
   489 => (x"9c",x"c3",x"4c",x"73"),
   490 => (x"c1",x"05",x"ac",x"c2"),
   491 => (x"66",x"c4",x"87",x"c4"),
   492 => (x"71",x"31",x"c9",x"49"),
   493 => (x"4a",x"66",x"c4",x"1e"),
   494 => (x"c2",x"92",x"c8",x"c1"),
   495 => (x"72",x"49",x"e9",x"f7"),
   496 => (x"d7",x"cd",x"fe",x"81"),
   497 => (x"ff",x"49",x"d8",x"87"),
   498 => (x"c8",x"87",x"c4",x"d7"),
   499 => (x"e5",x"c2",x"1e",x"c0"),
   500 => (x"e5",x"fd",x"49",x"d2"),
   501 => (x"d0",x"ff",x"87",x"ee"),
   502 => (x"78",x"e0",x"c0",x"48"),
   503 => (x"1e",x"d2",x"e5",x"c2"),
   504 => (x"c1",x"4a",x"66",x"cc"),
   505 => (x"f7",x"c2",x"92",x"c8"),
   506 => (x"81",x"72",x"49",x"e9"),
   507 => (x"87",x"ec",x"c8",x"fe"),
   508 => (x"ac",x"c1",x"86",x"cc"),
   509 => (x"87",x"c4",x"c1",x"05"),
   510 => (x"c9",x"49",x"66",x"c4"),
   511 => (x"c4",x"1e",x"71",x"31"),
   512 => (x"c8",x"c1",x"4a",x"66"),
   513 => (x"e9",x"f7",x"c2",x"92"),
   514 => (x"fe",x"81",x"72",x"49"),
   515 => (x"c2",x"87",x"cd",x"cc"),
   516 => (x"c8",x"1e",x"d2",x"e5"),
   517 => (x"c8",x"c1",x"4a",x"66"),
   518 => (x"e9",x"f7",x"c2",x"92"),
   519 => (x"fe",x"81",x"72",x"49"),
   520 => (x"d7",x"87",x"ea",x"c6"),
   521 => (x"e6",x"d5",x"ff",x"49"),
   522 => (x"1e",x"c0",x"c8",x"87"),
   523 => (x"49",x"d2",x"e5",x"c2"),
   524 => (x"87",x"e9",x"e3",x"fd"),
   525 => (x"d0",x"ff",x"86",x"cc"),
   526 => (x"78",x"e0",x"c0",x"48"),
   527 => (x"e3",x"fc",x"8e",x"f8"),
   528 => (x"5b",x"5e",x"0e",x"87"),
   529 => (x"1e",x"0e",x"5d",x"5c"),
   530 => (x"d4",x"ff",x"4d",x"71"),
   531 => (x"7e",x"66",x"d4",x"4c"),
   532 => (x"a8",x"b7",x"c3",x"48"),
   533 => (x"c0",x"87",x"c5",x"06"),
   534 => (x"87",x"e3",x"c1",x"48"),
   535 => (x"dc",x"fe",x"49",x"75"),
   536 => (x"1e",x"75",x"87",x"d5"),
   537 => (x"c1",x"4b",x"66",x"c4"),
   538 => (x"f7",x"c2",x"93",x"c8"),
   539 => (x"49",x"73",x"83",x"e9"),
   540 => (x"87",x"f2",x"ff",x"fd"),
   541 => (x"4b",x"6b",x"83",x"c8"),
   542 => (x"c8",x"48",x"d0",x"ff"),
   543 => (x"7c",x"dd",x"78",x"e1"),
   544 => (x"ff",x"c3",x"49",x"73"),
   545 => (x"73",x"7c",x"71",x"99"),
   546 => (x"29",x"b7",x"c8",x"49"),
   547 => (x"71",x"99",x"ff",x"c3"),
   548 => (x"d0",x"49",x"73",x"7c"),
   549 => (x"ff",x"c3",x"29",x"b7"),
   550 => (x"73",x"7c",x"71",x"99"),
   551 => (x"29",x"b7",x"d8",x"49"),
   552 => (x"7c",x"c0",x"7c",x"71"),
   553 => (x"7c",x"7c",x"7c",x"7c"),
   554 => (x"7c",x"7c",x"7c",x"7c"),
   555 => (x"c0",x"7c",x"7c",x"7c"),
   556 => (x"66",x"c4",x"78",x"e0"),
   557 => (x"ff",x"49",x"dc",x"1e"),
   558 => (x"c8",x"87",x"f9",x"d3"),
   559 => (x"26",x"48",x"73",x"86"),
   560 => (x"1e",x"87",x"df",x"fa"),
   561 => (x"bf",x"ec",x"e3",x"c2"),
   562 => (x"c2",x"b9",x"c1",x"49"),
   563 => (x"ff",x"59",x"f0",x"e3"),
   564 => (x"ff",x"c3",x"48",x"d4"),
   565 => (x"48",x"d0",x"ff",x"78"),
   566 => (x"ff",x"78",x"e1",x"c0"),
   567 => (x"78",x"c1",x"48",x"d4"),
   568 => (x"78",x"71",x"31",x"c4"),
   569 => (x"c0",x"48",x"d0",x"ff"),
   570 => (x"4f",x"26",x"78",x"e0"),
   571 => (x"00",x"00",x"00",x"00"),
   572 => (x"c2",x"1e",x"c0",x"1e"),
   573 => (x"49",x"bf",x"c9",x"e4"),
   574 => (x"c2",x"87",x"c6",x"fd"),
   575 => (x"49",x"bf",x"cd",x"e4"),
   576 => (x"87",x"d9",x"dd",x"fe"),
   577 => (x"26",x"26",x"48",x"c0"),
   578 => (x"00",x"29",x"11",x"4f"),
   579 => (x"00",x"29",x"1d",x"00"),
   580 => (x"58",x"54",x"4d",x"00"),
   581 => (x"20",x"32",x"31",x"35"),
   582 => (x"44",x"48",x"56",x"20"),
   583 => (x"58",x"54",x"4d",x"00"),
   584 => (x"20",x"32",x"31",x"35"),
   585 => (x"4d",x"4f",x"52",x"20"),
   586 => (x"4d",x"4f",x"52",x"00"),
		others => (others => x"00")
	);
	signal q1_local : word_t;

	-- Altera Quartus attributes
	attribute ramstyle: string;
	attribute ramstyle of ram: signal is "no_rw_check";

begin  -- rtl

	addr1 <= to_integer(unsigned(addr(ADDR_WIDTH-1 downto 0)));

	-- Reorganize the read data from the RAM to match the output
	q(7 downto 0) <= q1_local(3);
	q(15 downto 8) <= q1_local(2);
	q(23 downto 16) <= q1_local(1);
	q(31 downto 24) <= q1_local(0);

	process(clk)
	begin
		if(rising_edge(clk)) then 
			if(we = '1') then
				-- edit this code if using other than four bytes per word
				if (bytesel(3) = '1') then
					ram(addr1)(3) <= d(7 downto 0);
				end if;
				if (bytesel(2) = '1') then
					ram(addr1)(2) <= d(15 downto 8);
				end if;
				if (bytesel(1) = '1') then
					ram(addr1)(1) <= d(23 downto 16);
				end if;
				if (bytesel(0) = '1') then
					ram(addr1)(0) <= d(31 downto 24);
				end if;
			end if;
			q1_local <= ram(addr1);
		end if;
	end process;
  
end rtl;

