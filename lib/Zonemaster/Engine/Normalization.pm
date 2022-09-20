package Zonemaster::Engine::Normalization;

use 5.014002;

use utf8;
use strict;
use warnings;

use Carp;
use Encode;
use Readonly;
use Try::Tiny;
use Zonemaster::LDNS;
use Data::Dumper;

use Zonemaster::Engine::Normalization::Errors;

Readonly my $ASCII => qr/^[[:ascii:]]+$/;
Readonly my $VALID_ASCII => qr(^[A-Za-z0-9/_-]+$);

Readonly my $ASCII_FULL_STOP => "\x{002E}";
Readonly my $ASCII_FULL_STOP_RE => qr/\x{002E}/;
Readonly my %FULL_STOPS => (
    FULLWIDTH_FULL_STOP             => q/\x{FF0E}/,
    IDEOGRAPHIC_FULL_STOP           => q/\x{3002}/,
    HALFWIDTH_IDEOGRAPHIC_FULL_STOP => q/\x{FF61}/
);
Readonly my $FULL_STOPS_RE => (sub {
    my $re = '[' . (join '', values %FULL_STOPS) . ']';
    return qr/$re/;
})->();
Readonly my %WHITE_SPACES => (
    SPACE                     => q/\x{0020}/,
    CHARACTER_TABULATION      => q/\x{0009}/,
    NO_BREAK_SPACE            => q/\x{00A0}/,
    EN_QUAD                   => q/\x{2000}/,
    EM_QUAD                   => q/\x{2001}/,
    EN_SPACE                  => q/\x{2002}/,
    EM_SPACE                  => q/\x{2003}/,
    THREE_PER_EM_SPACE        => q/\x{2004}/,
    FOUR_PER_EM_SPACE         => q/\x{2005}/,
    SIX_PER_EM_SPACE          => q/\x{2006}/,
    FIGURE_SPACE              => q/\x{2007}/,
    PUNCTUATION_SPACE         => q/\x{2008}/,
    THIN_SPACE                => q/\x{2009}/,
    HAIR_SPACE                => q/\x{200A}/,
    MEDIUM_MATHEMATICAL_SPACE => q/\x{205F}/,
    IDEOGRAPHIC_SPACE         => q/\x{3000}/,
    OGHAM_SPACE_MARK          => q/\x{1680}/,
);
Readonly my $WHITE_SPACES_RE => (sub {
    my $re = '[' . (join '', values %WHITE_SPACES) . ']';
    return qr/$re/;
})->();
Readonly my %AMBIGUOUS_CHARACTERS => (
    "LATIN CAPITAL LETTER I WITH DOT ABOVE" => q/\x{0130}/,
);

sub normalize_label {
    my ( $label ) = @_;
    my @messages;

    my $alabel = "";

    if ( $label =~ $VALID_ASCII ) {
        $alabel = lc $label;
    } elsif ( $label =~ $ASCII ) {
        push @messages, Zonemaster::Engine::Normalization::Errors->new(INVALID_ASCII => {label => $label});

        return \@messages, undef;
    } elsif (Zonemaster::LDNS::has_idn) {
        try {
            $alabel = Zonemaster::LDNS::to_idn($label);
        } catch {
            push @messages, Zonemaster::Engine::Normalization::Errors->new(INVALID_U_LABEL => {label => $label});

            return \@messages, undef;
        }
    } else {
        croak 'The domain name contains at least one non-ASCII character and this installation of Zonemaster has no support for IDNA.';
    }

    if ( length($alabel) > 63) {
        push @messages, Zonemaster::Engine::Normalization::Errors->new(LABEL_TOO_LONG => {label => $label});
        return \@messages, undef;
    }

    return \@messages, $alabel;
}

sub normalize_name {
    my ( $uname ) = @_;
    my @messages;

    $uname =~ s/^${$WHITE_SPACES_RE}+//;
    $uname =~ s/${WHITE_SPACES_RE}+$//;

    if (length($uname) == 0) {
        push @messages, Zonemaster::Engine::Normalization::Errors->new(EMPTY_DOMAIN_NAME => {});
        return \@messages, undef;
    }

    foreach my $char_name (keys %AMBIGUOUS_CHARACTERS) {
        my $char = $AMBIGUOUS_CHARACTERS{$char_name};
        if ($uname =~ m/${char}/) {
            push @messages, Zonemaster::Engine::Normalization::Errors->new(AMBIGUOUS_DOWNCASING => { unicode_name => $char_name });
        }
    }

    if ( @messages ) {
        return \@messages, undef;
    }

    $uname =~ s/${FULL_STOPS_RE}/${ASCII_FULL_STOP}/g;

    if ( $uname eq $ASCII_FULL_STOP ) {
        return \@messages, $uname;
    }

    if ($uname =~ m/^${ASCII_FULL_STOP_RE}/) {
        push @messages, Zonemaster::Engine::Normalization::Errors->new(INITIAL_DOT => {});
        return \@messages, undef;
    }

    if ($uname =~ m/${ASCII_FULL_STOP_RE}{2,}/ ) {
        push @messages, Zonemaster::Engine::Normalization::Errors->new(REPEATED_DOTS => {});
        return \@messages, undef;
    }

    $uname =~ s/${ASCII_FULL_STOP_RE}$//g;

    my @labels = split $ASCII_FULL_STOP_RE, $uname;
    my @label_results = map { [ normalize_label($_) ] } @labels;
    my @label_errors = map { @{$_->[0]} } @label_results;

    push @messages, @label_errors;

    if ( @messages ) {
        return \@messages, undef;
    }

    my @label_ok = map { $_->[1] } @label_results;

    my $final_name = join '.', @label_ok;

    if (length($final_name) > 253) {
        push @messages, Zonemaster::Engine::Normalization::Errors->new(DOMAIN_NAME_TOO_LONG => {});
        return \@messages, undef;
    }

    return \@messages, $final_name;
}

1;
