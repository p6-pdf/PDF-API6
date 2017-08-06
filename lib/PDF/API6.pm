use v6;
use PDF::Lite;

class PDF::API6:ver<0.0.1>
    is PDF::Lite {

    use PDF::DAO;
    use PDF::Content::Page;

    sub nums($a, Int $n) {
        with $a {
            fail "expected $n elements, found {.elems}"
                unless $n == .elems;
            fail "array contains non-numeric elements"
                unless all(.list) ~~ Numeric;
        }
        True;
    }
    sub to-name(Str $name) { PDF::DAO.coerce: :$name }

    subset PageRef where {!.defined || $_ ~~ UInt|PDF::Content::Page};

    method open(|c) {
	my $doc = callsame;
	die "PDF file has wrong type: " ~ $doc.reader.type
	    unless $doc.reader.type eq 'PDF';
	$doc;
    }

    method catalog { self<Root> }

    method save-as($spec, Bool :$update is copy, |c) {

	if !$update and self.reader {
            with $.catalog<AcroForm> {
                # guard against signature invalidation
                my $sig-flags = .<SigFlags>;
                constant AppendOnly = 2;
                if $sig-flags && $sig-flags.flag-is-set: AppendOnly {
                    with $update {
                        # callee has specified :!update
                        die "This PDF contains digital signatures that will be invalidated with .save-as :!update"
                    }
                    else {
                        # set :update to preserve digital signatures
                        $update = True;
                    }
                }
            }
	}

        do {
            my $now = DateTime.now;
            my $info = self.info;

            with self.reader {
                # updating
                $info<ModDate> = $now;
            }
            else {
                # creating
                $info<Producer> //= "Perl 6 PDF::API6 {self.^ver}";
                $info<CreationDate> //= $now
            }
        }
	nextwith($spec, :$update, |c);
    }

    method update(|c) {
        # for the benefit of the test suite
        my $now = DateTime.now;
        my $Info = self<Info> //= {};
        $Info<ModDate> = $now;
        nextsame;
    }

    method preferences(
        Bool :$hide-toolbar,
        Bool :$hide-menubar,
        Bool :$hide-windowui,
        Bool :$fit-window,
        Bool :$center-window,
        Bool :$display-title,
        Str  :$direction where 'r2l'|'l2r'|!.defined,
        Str  :$page-mode where 'fullscreen'|'thumbs'|'outlines'|'none' = 'none';
        Str  :$page-layout where 'single-page'|'one-column'|'two-column-left'|'two-column-right' = 'single-page';
        Str :$after-fullscreen where 'thumbs'|'outlines'|'none'='none',
        Str :$print-scaling where 'none'|!.defined,
        Str :$duplex where 'simplex'|'flip-long-edge'|'flip-short-edge'|!.defined,
        :%first-page (
            PageRef :$page,
            Bool    :$fit,
            Numeric :$fith,
            Bool    :$fitb,
            Numeric :$fitbh,
            Numeric :$fitv,
            Numeric :$fitbv,
            List    :$fitr where nums($_, 4),
            List    :$xyz where nums($_, 3),
        ) where { .keys == 0 || .<page> }
        ) {
        my $catalog = $.catalog;

        constant %PageModes = %(
            :fullscreen<FullScreen>,
            :thumbs<UseThumbs>,
            :outline<UseOutlines>,
            :none<UseNone>,
            );

        $catalog<PageMode> = to-name( %PageModes{$page-mode} );

        $catalog<PageLayout> = to-name( %(
            :single-page<SinglePage>,
            :one-column<OneColumn>,
            :two-column-left<TwoColumnLeft>,
            :two-column-right<TwoColumnRight>,
            :single-page<SinglePage>,
            ){$page-layout});

        given $catalog<ViewerPreferences> //= { } {
            .<HideToolbar> = True if $hide-toolbar;
            .<HideMenubar> = True if $hide-menubar;
            .<HideWindowUI> = True if $hide-windowui;
            .<FitWindow> = True if $fit-window;
            .<CenterWindow> = True if $center-window;
            .<DisplayDocTitle> = True if $display-title;
            .<Direction> = to-name(.uc) with $direction;
            .<NonFullScreenPageMode> = to-name( %PageModes{$after-fullscreen});
            .<PrintScaling> = to-name('None') if $print-scaling ~~ 'none';
            with $duplex -> $dpx {
                .<Duplex> = to-name( %(
                      :simplex<Simplex>,
                      :flip-long-edge<DuplexFlipLongEdge>,
                      :flip-short-edge<DuplexFlipShortEdge>,
                    ){$dpx});
            }
        }
        if $page {
            my $page-ref = $page ~~ Numeric
                ?? self.page($page)
                !! $page;
            my $open-action = $catalog<OpenAction> = [$page-ref];
            with $open-action {
                when $fit   { .push: to-name('Fit') }
                when $fith  { .push($fith) }
                when $fitb  { .push: to-name('FitB') }
                when $fitbh {
                    .push: to-name('FitBH');
                    .push: $fitbh;
                }
                when $fitv {
                    .push: to-name('FitV');
                    .push: $fitv;
                }
                when $fitbv {
                    .push: to-name('FitBV');
                    .push: $fitbv;
                }
                when $fitr {
                    .push: to-name('FitR');
                    for $fitr.list -> $v {
                        .push: $v;
                    }
                }
                when $xyz {
                    .push: to-name('XYZ');
                    for $xyz.list -> $v {
                        .push: $v;
                    }
                }
            }
        }
    }

    method version {
        Proxy.new(
            FETCH => sub ($) {
                Version.new: $.catalog<Version> // self.reader.?version // '1.3'
            },
            STORE => sub ($, Version $v) {
                $.catalog<Version> = to-name( $v.Str );
            },
        );
    }

    method is-encrypted { ? self.Encrypt }
    method info { self<Info> //= {} }
    method xmp-metadata is rw {
        my $metadata = $.catalog<Metadata> //= PDF::DAO.coerce: :stream{
            :dict{
                :Type( to-name(<Metadata>) ),
                :Subtype( to-name(<XML>) ),
            }
        };

        $metadata.decoded; # rw target
    }

    our Str enum PageLabel «
         :Decimal<d>
         :RomanUpper<R> :RomanLower<r>
         :AlphaUpper<A> :AlphaLower<a>
        »;

    sub coerce-page-label(Hash $_) {
        my % = .pairs.map: {
            .key => .value ~~ Int ?? .value !! to-name(.value.Str)
        }
    }

    sub coerce-page-labels(List $_) {
        my @page-labels;
        my $elems = .elems;
        fail "PageLabel array has odd number of elements: {.perl}"
            unless $elems %% 2;
        my UInt $seq;
        loop (my $n = 0; $n < $elems;) {
            my $idx = .[$n++];
            fail "non-numeric PageLabel index at offset $n: $idx"
                unless $idx ~~ UInt;
            fail "out of sequence PageLabel index at offset $n: $idx"
                if $seq.defined && $idx <= $seq;
            $seq = $idx;
            my $dict = .[$n++];
            fail "page label is not a dict at offset $n"
                unless $dict ~~ Hash;
            @page-labels.push: $seq;
            @page-labels.push: coerce-page-label($dict);
        }
        @page-labels;
    }

    method PageLabels {
        Proxy.new(
            STORE => sub ($, List $labels) {
                $.catalog<PageLabels> = coerce-page-labels($labels);
            },
            FETCH => sub ($) {
                $.catalog<PageLabels>;
            }
            )
    }

}
