#REVISED: Angelox
#Zone: timorous
sub EVENT_SAY { 
if ($text=~/Hail/i){quest::say("Hello there. We have most the ships working again. If you need to [travel to Oasis] or want to [travel to Overthere] I can still help you with this."); }
if ($text=~/travel to oasis/i){quest::movepc(37,-821.31,884.23,0.1); }
#if ($text=~/travel to overthere/i){quest::say("The bloated Belly docks at the ogre camp"); }
#if ($text=~/travel to oasis/i){quest::say("Take the raft north of the ogre camp"); }
#if ($text=~/travel to firiona/i){quest::say("Take the shuttle to Firiona Vie"); }
if ($text=~/travel to overthere/i){quest::movepc(93, 2733.91,3423.82,-157.97); }
}