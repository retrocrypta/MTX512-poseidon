	//registers used:
		//r1: yes
		//r2: no
		//r3: no
		//r4: no
		//r5: no
		//r6: yes
		//r7: yes
		//tmp: yes
	.section	.text.0
	.global	_autoboot
_autoboot:
	stdec	r6

						//overrides.c, line 9
						// (a/p push)
						// a: pushed 0, regnames[sp] r6
						// (obj to tmp) flags 1 type 3
						// const
	.liconst	0
	stdec	r6
						// allocreg r1

						//overrides.c, line 9
		// Offsets 0, 0
		// Have am? no, no
		// flags 2, 4a
						// (a/p assign)
						// Destination is a register...
						// Destination is a variable with offset 0, 8
		// Real offset of type is 12, isauto 0
						// (prepobj r0)
 						// reg r1 - no need to prep
						// (obj to tmp) flags 2 type a
						// matchobj comparing flags 2 with 1
						// extern
	.liabs	_bootvhd_name
						//extern deref
						//sizemod based on type 0xa
	ldt
						// (save temp)isreg
	mr	r1
						//save_temp done

						//overrides.c, line 9
						//call
						//pcreltotemp
	.lipcrel	_diskimg_mount // extern
	add	r7
						// Deferred popping of 4 bytes (4 in total)
						// freereg r1
						// allocreg r1

						//overrides.c, line 10
		// Offsets 0, 0
		// Have am? no, no
		// flags 2, 4a
						// (a/p assign)
						// Destination is a register...
						// Destination is a variable with offset 0, 20
		// Real offset of type is 24, isauto 0
						// (prepobj r0)
 						// reg r1 - no need to prep
						// (obj to tmp) flags 2 type a
						// extern
	.liabs	_bootrom_name
						//extern deref
						//sizemod based on type 0xa
	ldt
						// (save temp)isreg
	mr	r1
						//save_temp done

						//overrides.c, line 10
						//call
						//pcreltotemp
	.lipcrel	_LoadROM // extern
	add	r7
						// Deferred popping of 0 bytes (4 in total)
						// freereg r1

						//overrides.c, line 11
						//setreturn
						// (obj to r0) flags 1 type a
						// const
	.liconst	0
	mr	r0
	ldinc	r6	// shortest way to add 4 to sp
	ldinc	r6
	mr	r7

	.section	.data.1
	.global	_bootvhd_name
_bootvhd_name:
						// Declaring from tree
						// static
	.ref	l1
	.section	.data.2
	.global	_bootrom_name
_bootrom_name:
						// Declaring from tree
						// static
	.ref	l2
	.section	.rodata.3
l1:
	.byte	77
	.byte	84
	.byte	88
	.byte	53
	.byte	49
	.byte	50
	.byte	32
	.byte	32
	.byte	86
	.byte	72
	.byte	68
	.byte	0
	.section	.rodata.4
l2:
	.byte	77
	.byte	84
	.byte	88
	.byte	53
	.byte	49
	.byte	50
	.byte	32
	.byte	32
	.byte	82
	.byte	79
	.byte	77
	.byte	0
