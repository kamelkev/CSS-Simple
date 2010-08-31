use Test::More;
plan(tests => 2);

use_ok('CSS::Simple');

my $css = <<END;
.foo {
	color: red;
}
.bar {
	color: blue;
	font-weight: bold;
}
.biz {
	color: green;
	font-size: 10px;
}
.foo2 {
	color: red;
}
.bar2 {
	color: blue;
	font-weight: bold;
}
.biz2 {
	color: green;
	font-size: 10px;
}
.foo3 {
	color: red;
}
.bar3 {
	color: blue;
	font-weight: bold;
}
.biz3 {
	color: green;
	font-size: 10px;
}
.foo4 {
	color: red;
}
.bar4 {
	color: blue;
	font-weight: bold;
}
.biz4 {
	color: green;
	font-size: 10px;
}
.foo5 {
	color: red;
}
.bar5 {
	color: blue;
	font-weight: bold;
}
.biz5 {
	color: green;
	font-size: 10px;
}
END

my $simple = CSS::Simple->new();

$simple->read({css => $css});

#shuffle stored styles around
my $shuffle1 = 0;
foreach (keys %{$simple->_get_css()}) { $shuffle1++;}

#shuffle stored styles around more
my $shuffle2 = 0;
while ( each %{$simple->_get_css()} ) {$shuffle2++;}

my $ordered = $simple->write();

# check to make sure that our shuffled hashes matched up...
ok($css eq $ordered);
