use Test;

my $minumum-version = Version.new('2019.07.1.357.gd.00674.b.31');

die "Scalar::History requires $minumum-version or later"
    if ( $*PERL.compiler.version cmp $minumum-version ) == Less;

class Scalar::History::Proxy is Proxy
{
    has @!history;
    has $!position;

    # This is needed for now since the standard ways
    # like assigning in the `has` statement, TWEAK
    # and BUILD don't work with `Proxy`

    method new( :&FETCH!, :&STORE!, *%_ ) is raw
    {
        my $self := self.Proxy::new( :&FETCH, :&STORE );
        $self.VAR.TWEAK( |%_ );
        $self
    }

    method TWEAK( :$!position = 0 ) {
        # yadayada
    }

    method current-value( \SELF: )
    {
        @!history[ $!position ]
    }

    method latest-value( \SELF: )
    {
        @!history[ *-1 ]
    }

    method get-history( \SELF: Bool :$all = False )
    {
        my $to-index = $all ?? @!history.elems - 1 !! $!position;
        @!history[ ^$to-index ]
    }

    method reset-history( \SELF: )
    {
        @!history = ();
        $!position = 0;
    }

    method forward-history( \SELF: $steps )
    {
        $!position = $!position + $steps;
        $!position = @!history.elems - 1
            if $!position >= @!history.elems;
        $!position;
    }

    method rewind-history( \SELF: $steps )
    {
        $!position = $!position - $steps;
        $!position = 0
            if $!position < 0;
        $!position;
    }

    method store-value( \SELF: $new-value, $register-duplicates )
    {
        # Forget stuff after rewind
        if @!history.elems > $!position + 1
        {
            @!history.splice( $!position + 1 );
        }

        if !($new-value eqv SELF.current-value) || $register-duplicates
        {
            @!history.push( $new-value );
            $!position = @!history.elems - 1;
        }
    }
}

class Scalar::History:ver<0.0.1>:auth<Markus 'Holli' Holzer>
{
    method create( $value, ::T $type = Any, Bool :$register-duplicates = False )
    {
        return-rw Scalar::History::Proxy.new(
            FETCH => method ( \SELF: ) {
                SELF.current-value() },
            STORE => method ( \SELF: T $new-value ) {
                SELF.store-value( $new-value, $register-duplicates ); }
        ) = $value;
    }
}

=begin pod

=head1 NAME

Scalar::History - A personal history for any scalar

=head1 DESCRIPTION

This module implements the history variable pattern, that is variables which store not only their current value, 
but also the values they have contained in the past.

You can make a history variable by calling the `create` function and bind (not assign) it to a scalar.
All assignments to the variable will be stored in a history and can be fetched at any point in your program.

=head1 SYNOPSIS

    use Scalar::History;

    # This adds a history to $abc
    my $abc := Scalar::History.create("a");

    # We can now assign new values
    $abc = "b";
    $abc = "d";

    # At any point we can ask for past values, here: ("a", "b")
    $abc.VAR.get-history.say;

    # Oh my, we forgot "c", we must rewind
    $abc.VAR.rewind-history( 1 );

    # So the current value is now "b" again
    $abc.say; 

    # rewinding only moves a pointer and you can
    # call `forward-history($steps)` to move into the
    # other (future) direction, no values get deleted.

    # But when we ask for the history we only get
    # historic values up to the current value, here ("a")
    $abc.VAR.get-history().say;

    # You can specify the :all adverb to get all historic
    # values, regardless. Here ("a", "b")
    say $abc.VAR.get-history( :all );

    # Notice there is no "d" in the history, it is here:
    say $abc.VAR.latest-value;

    # When assigning in a rewound state however, 
    # everything after the rewind point gets forgotten

    $abc = "c";
    $abc = "d";
    $abc = "e";

    $abc.say;                      # "e"
    $abc.VAR.get-history.say;      # ("a", "b", "c", "d")

    # You can enforce a type by passing it into `create`
    my Int $int := Scalar::History.create(1, Int);

    # The history variables behave just like normal ones
    $int++;

    # You can pass it to functions, but you need to use the `is raw`
    # in order to not lose the magic
    sub count-to-ten (Int $n is raw)
    {
        $n++;
        return-rw $n if $n == 10;
        return-rw count-to-ten( $n );
    }

    # Also, don't forget to bind the return value
    my $new := count-to-ten($int);

    $new.say;                      # 10
    $new.VAR.get-history.say;      # (1,2,3,4,5,6,7,8,9)

=head1 INSTALLATION

    $ zef install Scalar::History

=head1 HINT

If you want to make sure, you forward to the last known value, or rewind to the very first, you can call
the respective methods using `Inf` as argument.

=begin code
    $history.VAR.rewind-history( Inf );
=end code
=end pod

