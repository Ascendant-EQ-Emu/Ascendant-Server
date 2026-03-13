sub EVENT_SPAWN {
    # Equivalent to: $mob->SetRace(56);
    $npc->SetRace(56);
    $mob->ChangeSize(3);

    # Optional: force update to clients immediately (usually not needed)
    # $npc->SendIllusion();
}