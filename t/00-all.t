use Scalar::History;

use Test;


my $minumum-version = Version.new('2019.07.1.357.gd.00674.b.31');
ok( ($*PERL.compiler.version cmp $minumum-version) != Less, "Rakudo version >= 2019.07.1.357.gd.00674.b.31" );

subtest 'untyped' =>
{
    plan 2;

    my $sub = sub foo() { * };
    my $rx  = rx/x/;

    my $untyped := Scalar::History.create("a");
    $untyped = $sub;
    $untyped = $rx;
    $untyped = 42;
    ok( $untyped == 42, "Current value is correct" );
    is-deeply( $untyped.VAR.get-history, ("a", $sub, $rx), "History is correct" );
}

subtest 'typed' =>
{
    plan 3;

    my $typed := Scalar::History.create("a", Str);
    $typed = "b";
    $typed = "42";

    ok( $typed == "42", "Current value is correct" );
    is-deeply( $typed.VAR.get-history, ("a", "b"), "History is correct" );
    dies-ok( { $typed = 2; }, "Cannot assign invalid type" );
}

subtest 'duplicates' =>
{
    plan 2;

    my $with-duplicates := Scalar::History.create( "a", Str, :register-duplicates(True) );
    $with-duplicates = "a";
    $with-duplicates = "a";
    is-deeply( $with-duplicates.VAR.get-history, ("a", "a"), "duplicates get registered" );

    my $no-duplicates := Scalar::History.create( "a", Str );
    $no-duplicates = "a";
    $no-duplicates = "a";
    is-deeply( $no-duplicates.VAR.get-history, (), "duplicates get ignored" );
}

subtest 'position/forward/backward' =>
{
    plan 7;

    my Int $int := Scalar::History.create(10, Int);

    $int = 100 ;
    $int = 1000 ;
    $int.VAR.rewind-history(2);
    ok( $int == 10, "current value is correct after rewind" );

    $int.VAR.forward-history(1);
    ok( $int == 100, "current value is correct after forward" );

    $int.VAR.rewind-history(Inf);
    ok( $int == 10, "current value equals start value after rewind to infinity" );

    $int.VAR.forward-history(Inf);
    ok( $int == 1000, "current value equals last known value after forward to infinity" );

    $int.VAR.rewind-history(2);
    is-deeply( $int.VAR.get-history, (), "history empty after rewind" );
    is-deeply( $int.VAR.get-history(:all), (10, 100), "but still there if needed" );

    $int = 101;
    $int = 1001;
    is-deeply( $int.VAR.get-history, (10, 101), "history gets truncated after rewind and assign" );
}

subtest 'behaviour' =>
{
    plan 4;

    sub add-one( Int $v ) { return $v + 1 }

    my Int $int := Scalar::History.create(1, Int);

    $int++;
    $int = $int + 1;
    $int = add-one( $int );
    $int = 42;
    is-deeply( $int.VAR.get-history, (1,2,3,4), "historic Int behaves like normal Int" ); # probably testing the language here, but  meh

    $int.VAR.reset-history();
    is-deeply( $int.VAR.get-history(:all), (), "history can be reset" );

    my Int $foo = 11;
    $foo := Scalar::History.create($foo, Int);
    lives-ok { $foo == 11 && $foo.VAR.get-history }, 'can be initialized with a variable';

    $foo = 12;
    my Int $bar := Scalar::History.create($foo, Int);
    lives-ok { $bar == 12 && $bar.VAR.get-history }, 'can be initialized with a S::H';
}


done-testing;