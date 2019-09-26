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