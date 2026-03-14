# Jonas Quill - Name Change NPC (Guild Lobby)
# Author: Straps
#
# Grants a name change in exchange for 2 Marks of Ascendance.
# Uses $client->GrantNameChange() which triggers the standard EQ rename dialog
# on the player's next login / character select.

use strict;
use warnings;

our ($npc, $client, $name, $text, $popupid);

my $MOA_ITEM_ID = 1800; # Mark of Ascendance
my $MOA_COST    = 2;

my $POPUP_CONFIRM = 2001;
my $POPUP_CANCEL  = 2002;

sub EVENT_SAY {
    if ($text =~ /hail/i) {
        my $mark_count = $client->CountItem($MOA_ITEM_ID);

        plugin::Whisper("Well met, $name. I am Jonas Quill, scribe and keeper of names. For $MOA_COST Marks of Ascendance, I can grant you a fresh identity.");
        plugin::Whisper("You currently have $mark_count marks.");
        plugin::Whisper("If you'd like to proceed: " . quest::saylink("name change", 1, "[Name Change]"));
    }
    elsif ($text =~ /name change/i) {
        if ($client->IsNameChangeAllowed()) {
            plugin::Whisper("You already have a pending name change. Log out to character select to complete it first.");
            return;
        }

        my $mark_count = $client->CountItem($MOA_ITEM_ID);
        if ($mark_count < $MOA_COST) {
            plugin::Whisper("You need $MOA_COST Marks of Ascendance, but you only have $mark_count. Come back when you have enough.");
            return;
        }

        $client->Popup2(
            "Jonas Quill - Name Change",
            "<c \"#FFCC00\">Cost:</c> $MOA_COST Marks of Ascendance<br><br>"
            . "Your character will be flagged for a <c \"#00FF00\">name change</c>.<br><br>"
            . "After confirmation, <c \"#FFD700\">log out to character select</c> to enter your new name.<br><br>"
            . "Proceed?",
            $POPUP_CONFIRM,
            $POPUP_CANCEL,
            2, 0,
            "Confirm", "Cancel"
        );
    }
}

sub EVENT_POPUPRESPONSE {
    if ($popupid == $POPUP_CANCEL) {
        plugin::Whisper("Changed your mind? No problem. Your marks are safe.");
        return;
    }

    return unless $popupid == $POPUP_CONFIRM;

    # Re-validate
    if ($client->IsNameChangeAllowed()) {
        plugin::Whisper("You already have a pending name change.");
        return;
    }

    my $mark_count = $client->CountItem($MOA_ITEM_ID);
    if ($mark_count < $MOA_COST) {
        plugin::Whisper("You no longer have enough Marks of Ascendance.");
        return;
    }

    $client->RemoveItem($MOA_ITEM_ID, $MOA_COST);
    $client->GrantNameChange();

    plugin::Whisper("Done! $MOA_COST Marks of Ascendance consumed. Your new name awaits.");
    plugin::Whisper("Log out to character select and the rename screen will appear automatically.");
    $client->Message(15, "You have been granted a name change! Log out to character select to choose your new name.");
}

1;
