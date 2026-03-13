# ============================================================
# Guild Master NPC - Insight Training System
# Auto-detects trainer class from NPC class ID:
#   20=WAR 21=CLR 22=PAL 23=RNG 24=SHD 25=DRU 26=MNK 27=BRD
#   28=ROG 29=SHM 30=NEC 31=WIZ 32=MAG 33=ENC 34=BST 35=BER
# Works for all 16 guildmasters with a single script.
# Deploy to: quests/<zoneshortname>/<npcname>.pl
#            or quests/global/guildmaster.pl for all zones
# ============================================================

sub EVENT_SAY {
    my $trainer_class = $npc->GetClass() - 19;  # NPC class 20-35 → player class 1-16
    if ($trainer_class < 1 || $trainer_class > 16) {
        plugin::Whisper("I am not configured for training. Please report this.");
        return;
    }
    plugin::HandleSay($client, $text, $trainer_class);
}

sub EVENT_POPUPRESPONSE {
    my $trainer_class = $npc->GetClass() - 19;
    return if ($trainer_class < 1 || $trainer_class > 16);
    plugin::HandlePopupResponse($client, $popupid, $trainer_class);
}

sub EVENT_ITEM {
    my $trainer_class = $npc->GetClass() - 19;
    if ($trainer_class < 1 || $trainer_class > 16) {
        plugin::Whisper("I have no use for this.");
        plugin::return_items(\%itemcount);
        return;
    }

    # HandleTomeTurnin processes stacks and returns 1 on success, 0 on failure
    my $success = plugin::HandleTomeTurnin($npc, $client, \%itemcount, $trainer_class);

    unless ($success) {
        plugin::Whisper("I have no use for this.");
        plugin::return_items(\%itemcount);
    }
}
