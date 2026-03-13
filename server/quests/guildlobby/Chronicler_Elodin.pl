# Chronicler Elodin - Server Info & Guide NPC (Guild Lobby)
# Author: Straps
#
# Interactive help NPC that displays popup guides for all major server systems:
# overview, benedictions, marks of ascendance, AA tome system, transportation,
# and hub services. Pure information — no gameplay mechanics.

sub EVENT_SAY {
    if ($text =~ /hail/i) {
        plugin::Whisper("Greetings, $name. I am Chronicler Elodin, keeper of knowledge and guidance for those who walk these halls.");
        plugin::Whisper("I can share information about our realm's unique features:");
        plugin::Whisper(quest::saylink("server overview", 1)." | ".quest::saylink("ascendant buffs", 1)." | ".quest::saylink("marks of ascendance", 1)." | ".quest::saylink("aa tome system", 1));
        plugin::Whisper(quest::saylink("transportation", 1)." | ".quest::saylink("hub services", 1));
    }
    elsif ($text =~ /server overview/i) {
        my $popup_text = "<c \"#FFFFFF\"><b>Welcome to our Enhanced Classic Server!</b></c><br><br>";
        $popup_text .= "<c \"#FFD700\"><b>Server Philosophy:</b></c><br>";
        $popup_text .= "This server is designed around a <c \"#00FFFF\">solo or duo experience</c>, allowing adventurers to explore Norrath at their own pace without requiring large groups.<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>Key Features:</b></c><br>";
        $popup_text .= "<c \"#00FF00\">•</c> Multi-tiered progression system with powerful items<br>";
        $popup_text .= "<c \"#00FF00\">•</c> Server-wide Ascendant Benedictions (buffs)<br>";
        $popup_text .= "<c \"#00FF00\">•</c> Mark of Ascendance reward system<br>";
        $popup_text .= "<c \"#00FF00\">•</c> Enhanced AA abilities for convenience<br>";
        $popup_text .= "<c \"#00FF00\">•</c> Centralized hub with portal services<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>Item Tiers:</b></c><br>";
        $popup_text .= "The server features <c \"#00FFFF\">4 distinct item tiers</c> that provide progressive power increases as you adventure.<br>";
        $popup_text .= "<c \"#808080\">These powerful items are found throughout the world, rewarding exploration and combat.</c><br><br>";
        
        $popup_text .= "<c \"#808080\">Ask me about specific features for more details.</c>";
        
        $client->Popup2(
            "Server Overview",
            $popup_text,
            0, 0,
            0, 0
        );
    }
    elsif ($text =~ /ascendant buffs/i) {
        my $popup_text = "<c \"#FFCC00\"><b>Ascendant World Benedictions</b></c><br><br>";
        $popup_text .= "These are <c \"#00FFFF\">server-wide buffs</c> that benefit <c \"#FFD700\">ALL players</c> simultaneously, regardless of location.<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>Available Benedictions:</b></c><br>";
        $popup_text .= "<c \"#00FF00\">• Ascendant Haste</c> - Increased attack speed<br>";
        $popup_text .= "<c \"#00FF00\">• Ascendant Healing</c> - Enhanced regeneration<br>";
        $popup_text .= "<c \"#00FF00\">• Ascendant Run Speed</c> - Faster movement<br>";
        $popup_text .= "<c \"#00FF00\">• Ascendant Thought</c> - Improved mana regeneration<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>How It Works:</b></c><br>";
        $popup_text .= "Visit <c \"#00FFFF\">Exarch Valeth</c> in the Guild Lobby to check buff status and extend durations.<br><br>";
        $popup_text .= "Extensions cost <c \"#FFCC00\">1 Mark of Ascendance</c> and add <c \"#00FFFF\">6 hours</c> (max 48h).<br><br>";
        $popup_text .= "Buffs automatically reapply when you zone or log in!<br><br>";
        
        $popup_text .= "<c \"#808080\">These benedictions are a community effort - when one player extends them, everyone benefits!</c>";
        
        $client->Popup2(
            "Ascendant World Benedictions",
            $popup_text,
            0, 0,
            0, 0
        );
    }
    elsif ($text =~ /marks of ascendance/i) {
        my $popup_text = "<c \"#FFCC00\"><b>Marks of Ascendance</b></c><br><br>";
        $popup_text .= "Marks are the server's <c \"#FFD700\">premium currency</c>, earned through gameplay and used for special services.<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>How to Earn Marks:</b></c><br>";
        $popup_text .= "<c \"#00FF00\">• Online Time</c> - Random chance while playing (once per day)<br>";
        $popup_text .= "<c \"#00FF00\">• Combat</c> - Rare drop from defeating enemies (once per day)<br>";
        $popup_text .= "<c \"#808080\">Weekly limit: 7 marks total from both sources</c><br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>What Marks Are Used For:</b></c><br>";
        $popup_text .= "<c \"#00FFFF\">• Extending Ascendant Benedictions</c> (1 mark = 6 hours)<br>";
        $popup_text .= "<c \"#00FFFF\">• Future premium services</c> (more to come!)<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>Checking Your Balance:</b></c><br>";
        $popup_text .= "Hail <c \"#00FFFF\">Exarch Valeth</c> to see your current Mark count.<br><br>";
        
        $popup_text .= "<c \"#808080\">Marks are account-bound and cannot be traded.</c>";
        
        $client->Popup2(
            "Marks of Ascendance",
            $popup_text,
            0, 0,
            0, 0
        );
    }
    elsif ($text =~ /aa tome system/i) {
        my $popup_text = "<c \"#FFCC00\"><b>Alternative Advancement Tome System</b></c><br><br>";
        $popup_text .= "Discover powerful abilities from <c \"#FFD700\">other classes</c> through ancient tomes!<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>How It Works:</b></c><br>";
        $popup_text .= "<c \"#00FF00\">1. Find Illegible Tomes</c><br>";
        $popup_text .= "<c \"#808080\">  Drop from NPCs throughout the world</c><br>";
        $popup_text .= "<c \"#808080\">  Three tiers: Greater, Exalted, Ascendant</c><br><br>";
        
        $popup_text .= "<c \"#00FF00\">2. Translate the Tome</c><br>";
        $popup_text .= "<c \"#808080\">  Bring illegible tome + platinum to <c \"#00FFFF\">Haliax Greycloak</c></c><br>";
        $popup_text .= "<c \"#808080\">  Cost: 250pp (Greater), 500pp (Exalted), 1000pp (Ascendant)</c><br>";
        $popup_text .= "<c \"#808080\">  Receive random AA tome for that class</c><br><br>";
        
        $popup_text .= "<c \"#00FF00\">3. Learn the Ability</c><br>";
        $popup_text .= "<c \"#808080\">  Turn in translated tome to one of the class trainers for that AA <c \"#00FFFF\">class trainer</c></c><br>";
        $popup_text .= "<c \"#808080\">  Instantly gain the full AA (all ranks)</c><br>";
        $popup_text .= "<c \"#808080\">  No AA points required!</c><br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>Key NPCs:</b></c><br>";
        $popup_text .= "<c \"#00FFFF\">• Haliax Greycloak</c> - Tome translator (here in Guild Lobby)<br>";
        $popup_text .= "<c \"#00FFFF\">• Class Trainers</c> - Grant AAs from translated tomes<br><br>";
        
        $popup_text .= "<c \"#808080\">This system lets you gain powerful cross-class abilities that were previously unavailable to your class!</c>";
        
        $client->Popup2(
            "AA Tome System",
            $popup_text,
            0, 0,
            0, 0
        );
    }
    elsif ($text =~ /transportation/i) {
        my $popup_text = "<c \"#FFCC00\"><b>Getting Around Norrath</b></c><br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>AA Abilities (Always Available):</b></c><br>";
        $popup_text .= "<c \"#00FF00\">• Origin</c> - Returns you to your home city (bind point)<br>";
        $popup_text .= "<c \"#808080\">  Perfect for buying spells and supplies</c><br>";
        $popup_text .= "<c \"#00FF00\">• Marked Passage</c> - Teleports to Guild Lobby and back<br>";
        $popup_text .= "<c \"#808080\">  First cast: marks your location and goes to hub</c><br>";
        $popup_text .= "<c \"#808080\">  Second cast: returns you to marked location</c><br>";
        $popup_text .= "<c \"#808080\">  Location clears if you zone elsewhere</c><br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>Portal Services in Guild Lobby:</b></c><br>";
        $popup_text .= "<c \"#00FFFF\">• Spirekeeper Aethen</c> - Wizard spires to major cities<br>";
        $popup_text .= "<c \"#00FFFF\">• Circlekeeper Aurin</c> - Druid rings to natural zones<br>";
        $popup_text .= "<c \"#00FFFF\">• Nyra Silvermark</c> - Direct transport to Bazaar<br><br>";
        
        $popup_text .= "<c \"#808080\">Tip: Use Marked Passage to quickly return to the hub from anywhere!</c>";
        
        $client->Popup2(
            "Transportation Guide",
            $popup_text,
            0, 0,
            0, 0
        );
    }
    elsif ($text =~ /hub services/i) {
        my $popup_text = "<c \"#FFCC00\"><b>Guild Lobby Hub Services</b></c><br><br>";
        $popup_text .= "The Guild Lobby serves as the central hub for all adventurers.<br><br>";
        
        $popup_text .= "<c \"#FFD700\"><b>Key NPCs:</b></c><br>";
        $popup_text .= "<c \"#00FFFF\">• Exarch Valeth</c><br>";
        $popup_text .= "<c \"#808080\">  Manages Ascendant Benedictions</c><br>";
        $popup_text .= "<c \"#808080\">  Check buff status and extend durations</c><br><br>";
        
        $popup_text .= "<c \"#00FFFF\">• Spirekeeper Aethen</c><br>";
        $popup_text .= "<c \"#808080\">  Wizard portal network</c><br>";
        $popup_text .= "<c \"#808080\">  Access to all major wizard spires</c><br><br>";
        
        $popup_text .= "<c \"#00FFFF\">• Circlekeeper Aurin</c><br>";
        $popup_text .= "<c \"#808080\">  Druid circle network</c><br>";
        $popup_text .= "<c \"#808080\">  Access to all druid rings</c><br><br>";
        
        $popup_text .= "<c \"#00FFFF\">• Nyra Silvermark</c><br>";
        $popup_text .= "<c \"#808080\">  Steward of the Merchant Gate</c><br>";
        $popup_text .= "<c \"#808080\">  Quick transport to/from Bazaar</c><br><br>";
        
        $popup_text .= "<c \"#00FFFF\">• Kilven the Quartermaster</c><br>";
        $popup_text .= "<c \"#808080\">  General supplies and provisions</c><br><br>";
        
        $popup_text .= "<c \"#00FFFF\">• Haliax Greycloak</c><br>";
        $popup_text .= "<c \"#808080\">  Tome translator - converts illegible tomes</c><br>";
        $popup_text .= "<c \"#808080\">  Access cross-class AA abilities</c><br><br>";
        
        $popup_text .= "<c \"#00FFFF\">• Class Trainers</c><br>";
        $popup_text .= "<c \"#808080\">  Grant AA abilities from translated tomes</c><br><br>";
        
        $popup_text .= "<c \"#00FFFF\">• Chronicler Elodin</c> (that's me!)<br>";
        $popup_text .= "<c \"#808080\">  Server information and guidance</c><br><br>";
        
        $popup_text .= "<c \"#808080\">Hail any NPC to learn more about their services!</c>";
        
        $client->Popup2(
            "Guild Lobby Hub Services",
            $popup_text,
            0, 0,
            0, 0
        );
    }
}

1;
