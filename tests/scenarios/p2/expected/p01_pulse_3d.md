# p01_pulse_3d

Seed 1. Hand-derived from docs/notes/ticket-02.json (step k reads input k, event tick = k+1).

Pulse centre = feet + 0.8, 3D radius 5. S1 (4.9,0,0): sqrt(4.9^2+0.8^2)=4.965 <=5 -> stunned. S2 (4.95,0,0): sqrt(24.5025+0.64)=5.014 >5 -> NOT stunned (2D would hit).
Event pulse@1 {stunned_ids:[S1]}; carried 5-3=2; score 5 (one stun). pulse_cd: 180 at step 0 -> pulse_cd_s(1)=3.0, (91)=1.5.
Knockback 4 m over 15 ticks: S1 x = 4.9+4 = 8.9 (+-0.03) by tick 20. S2 stays chase (never stunned) and moves toward player: x(10)<4.95. Run 40 ticks (S2 would touch at ~60).
