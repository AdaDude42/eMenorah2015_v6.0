-- File Random.ads
with Interfaces.C; use Interfaces.C;
with Interfaces; use Interfaces;

-- Depends on rand8_16_32.c file

package RANDOM is

	package C renames Interfaces.C; use C;
 
	procedure Seed(s1 : C.char; s2 : C.char; s3 : C.char);
	pragma Import (C, Seed, "seed_rand8");
	

	function Rand_U8 return Unsigned_8;
	pragma Import (C, Rand_U8, "randomize");
	

	function Rand_U16 return Unsigned_16;
	pragma Import (C, Rand_U16, "random16");
	
 
	function Rand_U32 return Unsigned_32;
	pragma Import (C, Rand_U32, "random32");
 
end RANDOM;