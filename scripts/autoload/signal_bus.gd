# Autoload: SignalBus
extends Node
@warning_ignore_start("unused_signal")

signal channel_changed(new: Ghost.Channel, old: Ghost.Channel)
signal static_interference(amount: float)
signal skull_picked_up
signal stop_spawning_ghosts