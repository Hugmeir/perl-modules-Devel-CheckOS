use strict;
$^W = 1;

use Test::More tests => 23;
use File::Temp;
use File::Spec;
use Devel::CheckOS;
use Cwd;

my $cwd = getcwd();

emptydir();
MakefilePLexists();
BuildPLexists();
BuildPLandMakefilePLexist();
checkCopyCorrectModules();
checkDashl();

sub checkDashl {
    my $projectdir = File::Temp->newdir();
    chdir($projectdir);
    my $cmd = join(' ', map { qq{"$_"} } (
        $^X, (map { "-I$_" } @INC), $cwd.'/bin/use-devel-assertos', '-l'
    ));
    is_deeply(
        [sort (Devel::CheckOS::list_platforms())],
        [sort split(/, /, do { chomp($cmd = `$cmd`);$cmd })],
	'-l spews the right stuff'
    );
    chdir($cwd);
    ok(!-e File::Spec->catfile($projectdir, 'MANIFEST'),
        "... and doesn't write a MANIFEST");
    ok(!-e File::Spec->catfile($projectdir, 'Makefile.PL'),
        "... or a Makefile.PL");
    ok(!-e File::Spec->catdir($projectdir, 'inc'),
        "... or create directories");
}

sub checkCopyCorrectModules {
    my $projectdir = File::Temp->newdir();

    _run_script($projectdir, qw(Linux::v2_6 MicrosoftWindows));
    print "# use-devel-assertos Linux::v2_6 MicrosoftWindows\n";
    ok(-e File::Spec->catfile(
        $projectdir, qw(inc Devel AssertOS Linux v2_6.pm)),
	"inc/Devel/AssertOS/Linux/v2_6.pm exists");
    ok(-e File::Spec->catfile(
        $projectdir, qw(inc Devel AssertOS Linux.pm)),
	"inc/Devel/AssertOS/Linux.pm exists");
    ok(-e File::Spec->catfile(
        $projectdir, qw(inc Devel AssertOS MSWin32.pm)),
	"inc/Devel/AssertOS/MSWin32.pm exists");
    ok(-e File::Spec->catfile(
        $projectdir, qw(inc Devel AssertOS Cygwin.pm)),
	"inc/Devel/AssertOS/Cygwin.pm exists");
    ok(-e File::Spec->catfile(
        $projectdir, qw(inc Devel AssertOS MicrosoftWindows.pm)),
	"inc/Devel/AssertOS/MicrosoftWindows.pm exists");
    ok(-e File::Spec->catfile(
        $projectdir, qw(inc Devel AssertOS.pm)),
	"inc/Devel/AssertOS.pm exists");
    ok(-e File::Spec->catfile(
        $projectdir, qw(inc Devel CheckOS.pm)),
	"inc/Devel/CheckOS.pm exists");
    is_deeply(
        [sort split("\n", _getfile(File::Spec->catfile($projectdir, 'MANIFEST')))],
	[sort qw(
	    inc/Devel/AssertOS/Linux/v2_6.pm inc/Devel/AssertOS/Linux.pm
	    inc/Devel/AssertOS/MSWin32.pm inc/Devel/AssertOS/Cygwin.pm
	    inc/Devel/AssertOS/MicrosoftWindows.pm
	    inc/Devel/CheckOS.pm inc/Devel/AssertOS.pm
	    MANIFEST Makefile.PL
	)],
	'... and update MANIFEST correctly'
    );
}

sub BuildPLandMakefilePLexist {
    my $projectdir = File::Temp->newdir();
    _writefile(File::Spec->catfile($projectdir, 'Build.PL'),
        "build stuff");
    _writefile(File::Spec->catfile($projectdir, 'Makefile.PL'),
        "makefile stuff");

    _run_script($projectdir, qw(Linux MSWin32));
    is_deeply(
        _getfile(File::Spec->catfile($projectdir, 'Makefile.PL')),
        'use lib inc; use Devel::AssertOS qw(Linux MSWin32);

makefile stuff', # mmm, significant whitespace
        'if both exist, edit Makefile.PL'
    );
    is_deeply(
        _getfile(File::Spec->catfile($projectdir, 'Build.PL')),
        'use lib inc; use Devel::AssertOS qw(Linux MSWin32);

build stuff', # mmm, significant whitespace
        '... and Build.PL'
    );
}
sub BuildPLexists {
    my $projectdir = File::Temp->newdir();
    _writefile(File::Spec->catfile($projectdir, 'Build.PL'),
        "wibblywobblywoo");
    _writefile(File::Spec->catfile($projectdir, 'MANIFEST'),
        "HLAGH\n");

    _run_script($projectdir, qw(Linux MSWin32));
    ok(!-e File::Spec->catfile($projectdir, 'Makefile.PL'),
        'Makefile.PL not created');
    is_deeply(
        _getfile(File::Spec->catfile($projectdir, 'Build.PL')),
        'use lib inc; use Devel::AssertOS qw(Linux MSWin32);

wibblywobblywoo', # mmm, significant whitespace
        'if Build.PL exists, edit it'
    );
    is_deeply(
        [sort split("\n", _getfile(File::Spec->catfile($projectdir, 'MANIFEST')))],
	[sort qw(
	    inc/Devel/AssertOS/Linux.pm inc/Devel/AssertOS/MSWin32.pm
	    inc/Devel/CheckOS.pm inc/Devel/AssertOS.pm
	    HLAGH
	)],
	'... and update MANIFEST correctly'
    );
}

sub MakefilePLexists {
    my $projectdir = File::Temp->newdir();
    _writefile(File::Spec->catfile($projectdir, 'Makefile.PL'),
        "wibblywobblywoo");
    _writefile(File::Spec->catfile($projectdir, 'MANIFEST'),
        "HLAGH\n");

    _run_script($projectdir, qw(Linux MSWin32));
    ok(!-e File::Spec->catfile($projectdir, 'Build.PL'),
        'Build.PL not created');
    is_deeply(
        _getfile(File::Spec->catfile($projectdir, 'Makefile.PL')),
        'use lib inc; use Devel::AssertOS qw(Linux MSWin32);

wibblywobblywoo', # mmm, significant whitespace
        'if Makefile.PL exists, edit it'
    );
    is_deeply(
        [sort split("\n", _getfile(File::Spec->catfile($projectdir, 'MANIFEST')))],
	[sort qw(
	    inc/Devel/AssertOS/Linux.pm inc/Devel/AssertOS/MSWin32.pm
	    inc/Devel/CheckOS.pm inc/Devel/AssertOS.pm
	    HLAGH
	)],
	'... and update MANIFEST correctly'
    );
}

sub emptydir {
    my $projectdir = File::Temp->newdir();
    _run_script($projectdir, qw(Linux MSWin32));
    ok(-e File::Spec->catfile($projectdir, 'Makefile.PL'),
        "create Makefile.PL if there's neither Makefile.PL nor Build.PL");
    is_deeply(
        _getfile(File::Spec->catfile($projectdir, 'Makefile.PL')),
        'use lib inc; use Devel::AssertOS qw(Linux MSWin32);

', # mmm, significant whitespace
        '... and created it correctly'
    );
    is_deeply(
        [sort split("\n", _getfile(File::Spec->catfile($projectdir, 'MANIFEST')))],
	[sort qw(
	    inc/Devel/AssertOS/Linux.pm inc/Devel/AssertOS/MSWin32.pm
	    inc/Devel/CheckOS.pm inc/Devel/AssertOS.pm
	    MANIFEST Makefile.PL
	)],
	'... and MANIFEST created OK where there wasn\'t one'
    );
}

sub _getfile { open(my $fh, $_[0]) || return ''; local $/; return <$fh>; }
sub _writefile { open(my $fh, '>', shift()) || return ''; print $fh @_; }
sub _run_script {
    chdir(shift());
    system($^X, (map { "-I$_" } @INC), $cwd.'/bin/use-devel-assertos', '-q', @_);
    chdir($cwd);
}