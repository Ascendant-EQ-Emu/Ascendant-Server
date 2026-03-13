# A Temporary Helper - Tome Downgrade NPC (cshome)
# Author: Straps
#
# Accepts any Exalted or Ascendant illegible tome and downgrades it to the
# matching Greater tome for the same class. Useful when players have higher-tier
# tomes but need lower-tier credits.

use strict;
use warnings;

# EQEmu globals (required under strict)
our ($npc, $client, $text, %itemcount);

my $HELP_LINK    = quest::saylink("help", 1);
my $DETAILS_LINK = quest::saylink("details", 1);

# Map any accepted tome -> Greater tome for the same class
my %TO_GREATER = (
  # Bard
  121594 => 121592, # Ascendant -> Greater
  121593 => 121592, # Exalted   -> Greater

  # Beastlord
  121615 => 121613,
  121614 => 121613,

  # Berserker
  121618 => 121616,
  121617 => 121616,

  # Cleric
  121576 => 121574,
  121575 => 121574,

  # Druid
  121588 => 121586,
  121587 => 121586,

  # Enchanter
  121612 => 121610,
  121611 => 121610,

  # Magician
  121609 => 121607,
  121608 => 121607,

  # Monk
  121591 => 121589,
  121590 => 121589,

  # Necromancer
  121603 => 121601,
  121602 => 121601,

  # Paladin
  121579 => 121577,
  121578 => 121577,

  # Ranger
  121582 => 121580,
  121581 => 121580,

  # Rogue
  121597 => 121595,
  121596 => 121595,

  # Shadow Knight
  121585 => 121583,
  121584 => 121583,

  # Shaman
  121600 => 121598,
  121599 => 121598,

  # Warrior
  121573 => 121571,
  121572 => 121571,

  # Wizard
  121606 => 121604,
  121605 => 121604,
);

sub EVENT_SAY {
  return if (!$client);

  if ($text =~ /hail/i) {
    plugin::Whisper(
      "I offer a one-way trade. Hand me any [${DETAILS_LINK}] Exalted or Ascendant Illegible Advancement Tome "
      . "and I will return the matching Greater tome. Need [${HELP_LINK}]?"
    );
  }
  elsif ($text =~ /help/i) {
    plugin::Whisper(
      "Turn in: Illegible Tome of Exalted/Ascendant <Your Class> Advancement. "
      . "Receive: Illegible Tome of Greater <Your Class> Advancement. "
      . "Warning: the original tome is consumed. No refunds."
    );
  }
  elsif ($text =~ /details/i) {
    plugin::Whisper(
      "This is a pre-expansion safety valve. If you accidentally end up with higher-tier tomes, "
      . "I can reduce them to Greater so you can still progress normally."
    );
  }
}

sub EVENT_ITEM {
  return if (!$client);

  my $converted = 0;

  # Consume accepted tomes and return Greater equivalents
  foreach my $handin_id (keys %TO_GREATER) {
    while (quest::handin({ $handin_id => 1 })) {
      my $greater_id = $TO_GREATER{$handin_id};
      quest::summonitem($greater_id, 1);
      $converted++;

      plugin::Whisper("The ink dulls and the page softens... take your Greater tome.");
    }
  }

  if ($converted > 0) {
    plugin::Whisper("A temporary reprieve granted. (${converted} converted)");
  }

  # Return anything not handled above
  plugin::return_items(\%itemcount);
}
