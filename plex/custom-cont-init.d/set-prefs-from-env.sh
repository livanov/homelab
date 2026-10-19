#!/bin/bash
set -euo pipefail

PREFS="/config/Library/Application Support/Plex Media Server/Preferences.xml"

if [[ ! -f "${PREFS}" ]]; then
    echo "Preferences.xml does not exist yet (first start), restart the container to apply PLEX_PREF_* variables"
    exit 0
fi

# Rewrites through the open handle instead of replacing the file, so it keeps the ownership Plex needs.
# Empty values are skipped, so an unset .env variable leaves whatever is set in the Plex UI.
perl -e '
    my $path = shift;
    open(my $fh, "+<", $path) or die "$path: $!";
    my $xml = do { local $/; <$fh> };

    for my $var (sort grep { /^PLEX_PREF_/ } keys %ENV) {
        next if $ENV{$var} eq "";
        (my $name = $var) =~ s/^PLEX_PREF_//;
        (my $value = $ENV{$var}) =~ s/&/&amp;/g;
        $value =~ s/</&lt;/g;
        $value =~ s/>/&gt;/g;
        $value =~ s/"/&quot;/g;

        $xml =~ s/(<Preferences\b[^>]*?\s\Q$name\E=")[^"]*(")/$1$value$2/
            or $xml =~ s/(<Preferences\b[^>]*?)\s*(\/?>)/$1 $name="$value"$2/
            or die "no <Preferences> element in $path";
        print "set $name\n";
    }

    seek($fh, 0, 0);
    print $fh $xml;
    truncate($fh, tell($fh));
    close($fh);
' "${PREFS}"
