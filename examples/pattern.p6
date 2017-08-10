use v6;
use PDF::API6;
my PDF::API6 $pdf .= new;
my $page = $pdf.add-page;
$page.MediaBox = [0, 0, 230, 210];
my @Matrix = PDF::Content::Matrix::scale(.4);
my $pattern = $page.tiling-pattern: :BBox[0, 0, 100, 100], :@Matrix;
my $zfont = $pattern.core-font('ZapfDingbats');
$pattern.graphics: {
    .text: {
        .font = $zfont, 1;
        .TextMatrix = [64, 0, 0, 64, 7.1771, 2.4414];

        .FillColor = :DeviceRGB[1.0, 0.0, 0.0];
        .print: "♠";

        .TextMoveSet(0.7478, -0.007);
        .FillColor = :DeviceRGB[0.0, 1.0, 0.0];
        .print("♥");

        .TextMoveSet(-0.7323, 0.7813);
        .FillColor = :DeviceRGB[0.0, 0.0, 1.0];
        .print("♦");

        .TextMoveSet(0.6913, 0.007);
        .FillColor = :DeviceRGB[0.0, 0.0, 0.0];
        .print("♣");

    }
}

$page.graphics: {
    .FillColor = :DeviceRGB[1.0, 1.0, 0.0];
    .Rectangle(25, 175, 175, -150);
    .Fill;

    .FillColor = .use-pattern($pattern);

    .MoveTo(99.92, 49.92);                                # Start new path
    .CurveTo(99.92, 77.52, 77.52, 99.92, 49.92, 99.92);    # Construct lower-left circle
    .CurveTo(22.32, 99.92, -0.08, 77.52, -0.08, 49.92);
    .CurveTo(-0.08, 22.32, 22.32, -0.08, 49.92, -0.08);
    .CurveTo(77.52, -0.08, 99.92, 22.32, 99.92, 49.92);
    .FillStroke;

    .MoveTo(224.96, 49.92);                               # Start new path
    .CurveTo(224.96, 77.52, 202.56, 99.92, 174.96, 99.92); # Construct lower-right circle
    .CurveTo(147.36, 99.92, 124.96, 77.52, 124.96, 49.92);
    .CurveTo(124.96, 22.32, 147.36, -0.08, 174.96, -0.08);
    .CurveTo(202.56, -0.08, 224.96, 22.32, 224.96, 49.92);
    .FillStroke;

    .MoveTo(87.56, 201.70);                               # Start new path
    .CurveTo(63.66, 187.90, 55.46, 157.32, 69.26, 133.40); # Construct upper circle
    .CurveTo(83.06, 109.50, 113.66, 101.30, 137.56, 115.10);
    .CurveTo(161.46, 128.90, 169.66, 159.50, 155.86, 183.40);
    .CurveTo(142.06, 207.30, 111.46, 215.50, 87.56, 201.70);
    .FillStroke;

    .MoveTo(50, 50);         # Start new path
    .LineTo(175, 50);        # Construct triangular path
    .LineTo(112.5, 158.253);
    .CloseFillStroke;
}

$pdf.save-as('examples/pattern.pdf');