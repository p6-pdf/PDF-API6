#!/usr/bin/env perl6
use v6;
use PDF::API6;
use PDF::DAO::Type::Encrypt :PermissionsFlag;

sub MAIN(Str $out-file, *@in-files, Str :$save-as, Bool :$force)  {

    die "nothing to do"
	unless @in-files;

    my PDF::API6 $pdf .= open: $out-file;

    die "PDF forbids modification\n"
	unless $force || $pdf.permitted( PermissionsFlag::Modify );

    # create a new page root. 
    my $pages = $pdf.Root.Pages;

    for @in-files -> $in-file {
	my $in-pdf = PDF::API6.open: $in-file;

	die "PDF forbids copy: $in-file"
	    unless $force || $in-pdf.permitted( PermissionsFlag::Copy );

	$pages.add-pages: $in-pdf.Root.Pages;
    }

    with $save-as {
	# save to a new file
	$pdf.save-as: $_;
    }
    else {
	# inplace incremental update of first file
	$pdf.update;
    }
}

=begin pod

=head1 NAME

pdf-append.p6 - Append multiple PDF files

=head1 SYNOPSIS

 pdf-append.p6 [options] --save-as=output.pdf file1.pdf file2.pdf [file3.pdf...]

 Options:
   --save-as=file     save as a new PDF

=head1 DESCRIPTION

Copy the contents of C<file2.pdf> to the end of C<file1.pdf>.

=head1 SEE ALSO

PDF (Perl 6)
CAM::PDF (Perl 5)

=head1 AUTHOR

See L<CAM::PDF>

=cut

=end pod
