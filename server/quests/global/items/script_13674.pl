# Thank you to Skomag over at EQTitan for this.

# handles Vibrating Gauntlets/Hammer of Infuse
# clicking the items transmutes back and forth
# script file is used to bypass the lore check error
# 
# item 11668 Vibrating Gauntlets of Infuse
# item 11669 Vibrating Hammer of Infuse
# spell 1823 Transmute Gauntlets
# spell 1824 Transmute Hammer

#sub EVENT_ITEM_CLICK_CAST {
#        my %transmute = ();
#        $transmute[11668] = 1824;
#        $transmute[11669] = 1823;

#        if($itemid && $transmute[$itemid]) {
#                $client->NukeItem($itemid);
#                $client->CastSpell($transmute[$itemid], 0, 10, 0, 0);
#        }
#}

# handles Vibrating Gauntlets/Hammer of Infuse - all series
# clicking transmutes back and forth within the same tier
#
# Base:       11668 (Gauntlets) <-> 11669 (Hammer)
# Enhanced:  311668 (Gauntlets) <-> 311669 (Hammer)
# Exalted:   511668 (Gauntlets) <-> 511669 (Hammer)
# Ascendant: 711668 (Gauntlets) <-> 711669 (Hammer)

sub EVENT_ITEM_CLICK_CAST {
    my %swap = (
        11668  => 11669,
        11669  => 11668,
        311668 => 311669,
        311669 => 311668,
        511668 => 511669,
        511669 => 511668,
        711668 => 711669,
        711669 => 711668,
    );

    if ($itemid && exists $swap{$itemid}) {
        $client->NukeItem($itemid);
        quest::summonitem($swap{$itemid});
    }
}