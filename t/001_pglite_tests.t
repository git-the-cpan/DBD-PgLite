#!/usr/bin/perl -w

use strict;

use DBI;
use Test::More tests => 74;

my $fn = "/tmp/pglite_test.$$.sqlite";
my $dbh = DBI->connect('dbi:PgLite:dbname='.$fn);

# Scaffolding
ok( defined $dbh, "connect");
ok( -f $fn, "file present");
create_test_tables($dbh);
my $tpl = "select %s from animal natural join animal_sound natural join sound where %s";

# Tests of a few random features
is ( $dbh->selectrow_array(sprintf($tpl,"anim_name","sound_name = 'Bark'")), 
	 "Dog",
	 "simple natural join"
   );
is ( $dbh->selectrow_array(sprintf($tpl,"count(*)","sound_id = 4")), 
	 2,
	 "colname collision avoidance"
   );
is ( $dbh->selectrow_array(sprintf($tpl,"count(*)","sound_id = 4 and anim_active = 't'")), 
	 1,
	 "boolean col"
   );
is ( $dbh->selectrow_array(sprintf($tpl,"anim_name","sound_name ~ 'H' and anim_name ~* 's'")), 
	 "Snake",
	 "pattern match"
   );

# Mathematical functions
is ( functest($dbh,"abs(-2)"), 2, "abs()" );
is ( functest($dbh,"cbrt(8)"), 2, "cbrt()" );
is ( functest($dbh,"ceil(2.2)"), 3, "ceil()" );
is ( functest($dbh,"degrees(1)"), 57.2957795130823, "degrees()" );
is ( functest($dbh,"exp(1)"), 2.71828182845905, "exp()" );
is ( functest($dbh,"floor(2.2)"), 2, "floor()" );
is ( functest($dbh,"ln(2)"), 0.693147180559945, "ln()" );
is ( functest($dbh,"log(2)"), 0.301029995663981, "log() - 1-arg form" );
is ( functest($dbh,"log(2,2)"), 1, "log() - 2-arg form" );
is ( functest($dbh,"mod(8,5)"), 3, "mod()" );
is ( functest($dbh,"pi()"), 3.14159265358979, "pi()" );
is ( functest($dbh,"pow(2,2)"), 4, "pow()" );
is ( functest($dbh,"radians(1)"), 0.0174532925199433, "radians()" );
# round is already built-in:
# is ( functest($dbh,"round(2.2)"), 2, "round() - 1-arg form" );
# is ( functest($dbh,"round(2.22,1)"), 2.2, "round() - 2-arg form" );
is ( functest($dbh,"sign(-2)"), -1, "sign()" );
is ( functest($dbh,"sqrt(25)"), 5, "sqrt()" );
is ( functest($dbh,"trunc(2.21)"), 2, "trunc() - 1-arg form" );
is ( functest($dbh,"trunc(2.21,1)"), 2.2, "trunc() - 2-arg form" );
is ( functest($dbh,"acos(1)"), 0, "acos()" );
is ( functest($dbh,"asin(0)"), 0, "asin()" );
is ( functest($dbh,"atan(0)"), 0, "atan()" );
is ( functest($dbh,"atan2(0,1)"), 0, "atan2()" );
is ( functest($dbh,"cos(0)"), 1, "cos()" );
is ( functest($dbh,"cot(0.00000001)"), 100000000, "cot()" );
is ( functest($dbh,"sin(0)"), 0, "sin()" );
is ( functest($dbh,"tan(0)"), 0, "tan()" );
# random() and setseed() are not entirely compatible with Pg:
# is ( functest($dbh,"setseed(1)"), 2147483647, "setseed()" );
# is ( functest($dbh,"random()"), 0.496240361824744, "random()" );


# String functions
is ( functest($dbh,"ascii('a')"), 97, "ascii()");
is ( functest($dbh,"bit_length('a')"), 8, "bit_length()");
is ( functest($dbh,"btrim('xyxbtrimyyx','xy')"), "btrim", "btrim()");
is ( functest($dbh,"char_length('ab')"), 2, "char_length()");
is ( functest($dbh,"character_length('ab')"), "2", "character_length()");
is ( functest($dbh,"chr(97)"), "a", "chr()");
is ( functest($dbh,"convert('�','LATIN1')"), "�", "convert() (2-arg)");
is ( functest($dbh,"convert('�','LATIN1','UTF8')"), "á", "convert() (3-arg)");
is ( functest($dbh,"decode('UGdMaXRl', 'base64')"), "PgLite", "decode()");
is ( functest($dbh,"encode('PgLite','base64')"), "UGdMaXRl", "encode()");
is ( functest($dbh,"initcap('abc')"), "Abc", "initcap()");
is ( functest($dbh,"length('a')"), 1, "length()");
is ( functest($dbh,"lpad('hi', 7, 'xyn')"), "xynxyhi", "lpad()");
is ( functest($dbh,"ltrim('zzzyltrim', 'xyz')"), "ltrim", "ltrim()");
is ( functest($dbh,"md5('abc')"), "900150983cd24fb0d6963f7d28e17f72", "md5()");
is ( functest($dbh,"octet_length('ab')"), 2, "octet_length()");
is ( functest($dbh,"position('Li' in 'PgLite')"), 3, "position()");
is ( functest($dbh,"pg_client_encoding()"), "SQL_ASCII", "pg_client_encoding()");
is ( functest($dbh,"quote_ident('a b')"), '"a b"', "quote_ident()");
is ( functest($dbh,"quote_literal(?)","I'm OK"), "'I''m OK'", "quote_literal()");
is ( functest($dbh,"repeat('XY',3)"), "XYXYXY", "repeat()");
is ( functest($dbh,"replace('abc','c','z')"), "abz", "replace()");
is ( functest($dbh,"rpad('hi',7,'xyn')"), "hixynxy", "rpad()");
is ( functest($dbh,"rtrim('trimxxxx', 'x')"), "trim", "rtrim()");
is ( functest($dbh,"split_part('a_b_c_d','_',3)"), "c", "split_part()");
is ( functest($dbh,"strpos('abcd','c')"), 3, "strpos()");
is ( functest($dbh,"substring('abcd',2,2)"), "bc", "substring(string,offset,length)");
is ( functest($dbh,"substring('abcd' from '^..')"), "ab", "substring(string from pattern)");
is ( functest($dbh,"to_ascii('�����')"), "aeidt", "to_ascii()");
is ( functest($dbh,"to_hex(2006)"), "7d6", "to_hex()");
is ( functest($dbh,"translate('12345', '14', 'ax')"), "a23x5", "translate()");
is ( functest($dbh,"trim('  abc   ')"), "abc", "trim()");

# Datatype formatting functions
# Need better coverage to test formatting string elements
is (functest($dbh,"to_char('2006-01-02 20:30:33.92919','Mon FMDD, FMHH12:MIAM')"), "Jan 2, 8:30PM", "to_char(timestamp, format)" );
is ( $dbh->selectrow_array(sprintf($tpl,"extract(day from anim_added)","anim_id = 1")), 
	 1,
	 "extract day"
   );
is ( $dbh->selectrow_array(sprintf($tpl,"to_char(anim_added,'FMDD.FMMM.YY')","anim_id = 1")), 
	 "1.1.06",
	 "to_char (from table)"
   );

# Sequence functions
is ( functest($dbh,"nextval('animal_anim_id_seq')"), 8, "nextval()" );
is ( functest($dbh,"currval('animal_anim_id_seq')"), 7, "currval()" );

# Aggregate functions
is ( $dbh->selectrow_array(sprintf($tpl,"avg(decibels)","anim_active = 't'")), 55.625, "avg()");

# Casting
is ( functest($dbh,"5.54::int"), 6, "cast to int");
is ( functest($dbh,"'t'::bool"), 1, "cast to bool");
is ( $dbh->selectrow_array(sprintf($tpl,"anim_added::date","anim_id = 1")), "2006-01-01", "cast to date");
is ( $dbh->selectrow_array(sprintf($tpl,"(decibels::float)/3.2","anim_id = 1")), "21.875", "cast to float");

# Stored procedures
is ( $dbh->selectrow_array(sprintf($tpl,"lcname(anim_id)","anim_id = 1")), 'dog', "stored procedures");

# clean up
unlink($fn);

######### SUBS BELOW #########

sub functest {
	my ($dbh,$expr,@bind) = @_;
	return $dbh->selectrow_array("SELECT $expr",{},@bind);
}

sub create_test_tables {
	my $dbh = shift;
	my $sql = <<'EOF';
 CREATE TABLE animal (
   anim_id     int primary key not null,
   anim_name   text,
   anim_active boolean,
   anim_added  timestamp
 );
 INSERT INTO animal VALUES (1, 'Dog', TRUE, '2006-01-01 23:45:12');
 INSERT INTO animal VALUES (2, 'Cat', TRUE, '2006-01-02 23:45:12');
 INSERT INTO animal VALUES (3, 'Horse', TRUE, '2006-01-03 23:45:12');
 INSERT INTO animal VALUES (4, 'Lion', TRUE, '2006-01-04 23:45:12');
 INSERT INTO animal VALUES (5, 'Brontosaurus', FALSE, '2006-01-05 23:45:12');
 INSERT INTO animal VALUES (6, 'Giraffe', TRUE, '2006-01-06 23:45:12');
 INSERT INTO animal VALUES (7, 'Snake', TRUE, '2006-01-07 23:45:12');
 CREATE TABLE sound (
   sound_id   int primary key not null,
   sound_name text,
   decibels   int
 );
 INSERT INTO sound VALUES (1, 'Bark', 70);
 INSERT INTO sound VALUES (2, 'Growl', 45);
 INSERT INTO sound VALUES (3, 'Miauw', 45);
 INSERT INTO sound VALUES (4, 'Roar', 110);
 INSERT INTO sound VALUES (5, 'Whinny', 50);
 INSERT INTO sound VALUES (6, 'Hiss', 40);
 CREATE TABLE animal_sound (
   anim_id  int not null,
   sound_id int not null,
   primary key (anim_id, sound_id)
 );
 INSERT INTO animal_sound VALUES (1,1);
 INSERT INTO animal_sound VALUES (1,2);
 INSERT INTO animal_sound VALUES (2,3);
 INSERT INTO animal_sound VALUES (2,6);
 INSERT INTO animal_sound VALUES (3,5);
 INSERT INTO animal_sound VALUES (4,4);
 INSERT INTO animal_sound VALUES (4,2);
 INSERT INTO animal_sound VALUES (5,4);
 INSERT INTO animal_sound VALUES (7,6);
 CREATE TABLE pglite_functions (
   name   text,
   argnum int,
   type   text,
   sql    text,
   primary key (name, argnum)
 );
 INSERT INTO pglite_functions VALUES (
   'lcname', 1, 'sql', 'SELECT LOWER(anim_name) FROM animal WHERE anim_id = $1'
 );
EOF
  ;
	foreach (split /;/, $sql) {
		$dbh->do($_) if /\w/;
	}
	DBD::PgLite::_register_stored_functions($dbh);
}