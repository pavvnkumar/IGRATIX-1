# IGRATIX-1 — MASTER PROJECT CONTEXT

You are assisting with a serious commercial-oriented semiconductor development project.

Treat IGRATIX-1 as a real ASIC/product development project, not a tutorial.

## PRODUCT

Name: IGRATIX-1

Product:
16-channel programmable PWM controller.

Locked functional target:

* 16 independent PWM channels
* 12-bit duty-cycle resolution
* I2C slave interface
* Programmable PWM frequency
* Per-channel PWM duty-cycle control
* Output Enable (OE)
* Global/group update
* Synchronized shadow-to-active PWM updates
* Software reset
* Deterministic hardware reset
* 3.3-V digital-core assumption
* Fully synthesizable RTL
* Deterministic behavior
* Robust invalid/unexpected I2C handling
* No CPU
* No ADC
* No DAC
* No analog constant-current sink
* No DMX
* No DALI
* No unnecessary advanced features

Do not revisit product selection unless an actual toolchain, PDK, synthesis, verification, or physical-design constraint proves a specified component technically unsuitable.

## DEVELOPMENT MODE

Primary objective:

TIME → PRODUCT → VERIFICATION → TAPE-OUT

Use:

Requirement
→ RTL
→ unit verification
→ integration
→ software/program test
→ regression
→ measurement
→ fix
→ checkpoint/commit
→ next block

Do not over-teach basic RTL, SystemVerilog, Verilator, I2C, Git, Make, simulation, or RISC concepts.

Explain only what is required for an engineering decision unless explicitly asked for deeper explanation.

Prefer exact commands, exact files, exact RTL, exact tests, and concrete next actions.

Do not tell the user merely what they should implement.

When a task is selected, provide the implementation step-by-step and guide the user through execution.

## ENGINEERING PRIORITIES

P0 = required for chip functionality.

P1 = required for reliable tape-out/signoff.

P2 = meaningful engineering quality.

P3 = learning/nice-to-have.

Never allow P3 work to delay P0/P1.

Priority order:

1. Correctness
2. Synthesizability
3. Verification
4. Area/timing/power optimization
5. Feature expansion

Avoid unnecessary features and unnecessary parameterization.

Prefer simple deterministic RTL.

Keep interfaces clean and stable.

Do not redesign working architecture without evidence.

## IMPLEMENTATION STATUS VS TAPE-OUT STATUS

Always maintain two separate statuses.

IMPLEMENTATION STATUS:
What has actually been implemented, compiled, simulated, verified, synthesized, etc.

TAPE-OUT READINESS:
What remains before credible ASIC signoff.

Passing RTL simulation is NOT tape-out readiness.

Never claim a stage passed unless actual tool output confirms it.

## BASE REPOSITORY

Current repository:

IGRATIX-1/

rtl/
top/
i2c/
registers/
pwm/
common/

tb/
directed/
assertions/
regression/

sim/

constraints/

scripts/

docs/

build/

reports/

Current documentation files:

README.md
docs/ARCHITECTURE.md
docs/REGISTER_MAP.md
docs/VERIFICATION.md
docs/SYNTHESIS.md
docs/PHYSICAL_DESIGN.md
docs/TAPEOUT_CHECKLIST.md

Add files only when they have a real purpose.

## TOP-LEVEL ARCHITECTURE

Top-level module:

igratix1_top

Target hierarchy:

igratix1_top
├── i2c_slave
├── register_bank
├── pwm_controller
├── update_sync
└── clock/reset/control logic

The internal hierarchy may change if actual synthesis/verification evidence supports a better implementation, but external functionality must remain unchanged.

## TOP-LEVEL EXTERNAL INTERFACE

Initial logical interface:

clk
rst_n
scl
sda
oe
pwm[15:0]

Definitions:

clk:
system clock.

rst_n:
active-low hardware reset.

scl:
I2C clock input.

sda:
I2C bidirectional/open-drain data interface.

oe:
active-high logical output-enable control unless the actual selected IO strategy requires an external polarity adaptation.

pwm[15:0]:
16 PWM output channels.

Do not invent PDK pad cells.

The actual PDK IO implementation is a later integration task.

## CLOCK ARCHITECTURE

Use a simple digital clock architecture.

No PLL.

No analog clock-generation IP.

No unnecessary mixed-signal logic.

Initial RTL/test environment may use a practical system clock such as 25 MHz for development, but the final clock frequency is not considered frozen until the selected ASIC flow/PDK requirements are verified.

PWM frequency is generated digitally.

Initial PWM timing model:

16-bit programmable divider.

12-bit PWM counter.

A PWM tick occurs every:

PWM_DIV + 1

system-clock cycles.

The PWM counter cycles through 4096 counts.

Nominal PWM frequency:

f_pwm = f_clk / ((PWM_DIV + 1) × 4096)

Do not claim a final operating frequency until timing analysis establishes it.

## PWM ARCHITECTURE

There are 16 independent logical PWM channels.

Each channel has:

* 12-bit shadow duty register
* 12-bit active duty register
* PWM output logic

PWM counter is shared across all 16 channels unless synthesis/measurement proves a better architecture necessary.

Duty range:

0x000–0xFFF

Required behavior:

0x000 = 0% duty

0xFFF = 100% duty

Intermediate values produce corresponding duty cycle.

The implementation must explicitly handle 0% and 100% so there is no off-by-one ambiguity.

Do not rely on accidental comparator behavior for endpoint semantics.

## PWM UPDATE ARCHITECTURE

Software writes modify SHADOW registers.

ACTIVE PWM values do not change immediately during normal operation.

An update request causes shadow values to become active synchronously at a safe PWM boundary.

Update sources:

* global update
* group update

Four groups:

Group 0 = channels 0–3
Group 1 = channels 4–7
Group 2 = channels 8–11
Group 3 = channels 12–15

Global update affects all channels.

Group update affects only the selected group.

The update operation must not create visible mid-period PWM glitches.

## REGISTER MAP

Use a simple independent IGRATIX register map.

Do not clone the PCA9685 register map.

Control registers:

0x00 CONTROL
0x01 STATUS
0x02 PWM_DIV_L
0x03 PWM_DIV_H
0x04 UPDATE
0x05 OE_CTRL
0x06 SW_RESET
0x07 DEVICE_ID

PWM registers:

0x10–0x2F

Each channel occupies two bytes.

Channel mapping:

CH0 = 0x10–0x11
CH1 = 0x12–0x13
CH2 = 0x14–0x15
CH3 = 0x16–0x17
CH4 = 0x18–0x19
CH5 = 0x1A–0x1B
CH6 = 0x1C–0x1D
CH7 = 0x1E–0x1F
CH8 = 0x20–0x21
CH9 = 0x22–0x23
CH10 = 0x24–0x25
CH11 = 0x26–0x27
CH12 = 0x28–0x29
CH13 = 0x2A–0x2B
CH14 = 0x2C–0x2D
CH15 = 0x2E–0x2F

Only bits [11:0] contain duty information.

Bits [15:12] are reserved and read as zero.

UPDATE register:

bit 0 = global update
bit 1 = group 0 update
bit 2 = group 1 update
bit 3 = group 2 update
bit 4 = group 3 update

Writes to UPDATE generate update requests.

Requests are consumed synchronously.

The exact CONTROL/STATUS/DEVICE_ID bit definitions should be documented before RTL depends on them.

## I2C ARCHITECTURE

I2C slave must support:

* slave address recognition
* write transactions
* read transactions
* register addressing
* ACK
* NACK
* repeated START where practical
* STOP
* invalid transaction handling
* deterministic reset

Do not add clock stretching unless required by the actual implementation.

Prefer a simple robust implementation.

The I2C interface must not directly create unsafe asynchronous control signals in the PWM domain.

Any cross-domain transaction/control event must use a deliberate synchronization strategy.

The implementation strategy must be selected based on the actual system clock and target I2C speed.

## I2C ADDRESS

The IGRATIX-1 slave address must be documented and treated as a configurable integration decision before final tape-out.

Do not silently assume the PCA9685 address.

If address programmability is not required by the locked product specification, keep it simple.

## REGISTER BANK

The register bank is responsible for:

* decoding register addresses
* write data
* read data
* shadow PWM registers
* divider registers
* control/status registers
* update requests
* software reset request

It should not contain PWM timing logic.

Keep configuration and datapath responsibilities separated.

## SOFTWARE RESET

Software reset is generated through the SW_RESET register.

A valid software reset command must restore the same deterministic functional state defined for reset, unless a specific register is intentionally retained and documented.

Software reset must not create ambiguous partial PWM state.

I2C must return to a deterministic idle state.

## HARDWARE RESET

After hardware reset:

* PWM outputs are safe/inactive
* PWM active duty values are zero
* PWM shadow duty values are zero
* PWM counter is zero
* divider has a documented default
* OE is disabled
* I2C returns to idle
* register state is deterministic

Exact reset values must be documented in REGISTER_MAP.md.

## OE

OE provides a deterministic way to disable all PWM outputs.

When disabled:

PWM outputs must be forced to the safe inactive state.

OE must not corrupt PWM configuration registers.

When re-enabled, active PWM configuration resumes deterministically.

## VERIFICATION

Verification is risk-driven.

Required tests include:

1. hardware reset
2. I2C address recognition
3. I2C write
4. I2C read
5. register addressing
6. all 16 channels
7. 0% duty
8. 100% duty
9. intermediate duty values
10. PWM frequency configuration
11. synchronized update
12. global update
13. group update
14. OE
15. software reset
16. repeated register updates
17. boundary values
18. invalid I2C transactions
19. reset during activity where practical
20. simultaneous operation of all 16 channels

Use assertions where they provide real value.

Use automated regression.

Do not create artificial educational tests with no engineering value.

## VERIFICATION LAYERS

Layer 1:
PWM unit test.

Layer 2:
register-bank test.

Layer 3:
I2C slave test.

Layer 4:
16-channel PWM test.

Layer 5:
full top-level integration.

Layer 6:
software/program-driven integration tests.

Layer 7:
full regression.

Layer 8:
lint/synthesis verification.

Layer 9:
physical verification.

## SYNTHESIS REQUIREMENTS

RTL must be synthesizable.

Avoid:

* simulation-only constructs in RTL
* vendor-specific constructs
* accidental latches
* unintended inferred memories
* asynchronous combinational feedback
* unsynchronized control crossings
* unnecessary high-fanout structures

After synthesis:

check:

* successful elaboration
* inferred hardware
* latch warnings
* inferred memory warnings
* area
* timing
* clock constraints
* reset implementation

Do not claim ASIC suitability based only on simulation.

## ASIC FLOW

After verified RTL:

1. lint
2. elaboration
3. synthesis
4. timing constraints
5. timing analysis
6. area analysis
7. floorplanning
8. placement
9. CTS where applicable
10. routing
11. DRC
12. LVS
13. antenna checks where applicable
14. final GDS
15. reproducibility/archive check
16. final tape-out checklist

The selected PDK/MPW route, IO cells, package, die-size limits, shuttle date, commercial terms, and submission requirements remain UNKNOWN until verified from actual provider documentation.

Never invent these.

## PHYSICAL DESIGN

The design should remain small and regular.

Prefer:

* shared PWM counter
* compact register bank
* simple I2C logic
* minimal clocking
* deterministic reset
* low unnecessary fanout
* simple control paths

Do not optimize prematurely.

Measure synthesis results before making area/timing changes.

## DOCUMENTATION

Maintain:

README.md
ARCHITECTURE.md
REGISTER_MAP.md
VERIFICATION.md
SYNTHESIS.md
PHYSICAL_DESIGN.md
TAPEOUT_CHECKLIST.md

Documentation must describe actual implementation, not planned behavior, once implementation begins.

Clearly label:

IMPLEMENTED
VERIFIED
TBD
UNKNOWN
ASSUMPTION

## DEVELOPMENT STAGES

Stage 1:
repository + specification + environment

Stage 2:
I2C slave

Stage 3:
register bank

Stage 4:
single PWM channel

Stage 5:
16-channel PWM

Stage 6:
full integration

Stage 7:
full regression

Stage 8:
synthesis

Stage 9:
physical design

Stage 10:
DRC/LVS/final GDS

However, implementation and verification should overlap where dependencies allow.

Do not wait until the end to discover integration failures.

## CHECKPOINT RULE

After every working stage:

* compile
* simulate
* run relevant tests
* inspect failures
* fix
* run regression
* preserve logs/reports
* Git commit/checkpoint

Never declare success without actual tool evidence.

## FINAL ACCEPTANCE

IGRATIX-1 implementation is complete only when:

[ ] RTL compiles
[ ] directed tests pass
[ ] regression passes
[ ] assertions pass
[ ] I2C verified
[ ] all 16 PWM channels verified
[ ] boundaries verified
[ ] reset verified
[ ] OE verified
[ ] synchronized update verified
[ ] synthesis succeeds
[ ] no unexpected latches
[ ] no unintended inferred memories
[ ] timing analyzed
[ ] area analyzed
[ ] physical design completes
[ ] DRC passes or all violations are explicitly understood
[ ] LVS passes
[ ] final GDS generated
[ ] source/tool versions archived
[ ] tape-out checklist complete
[ ] PDK/MPW/IO/package/submission requirements actually verified
[ ] documentation updated

Do not start IGRATIX-2.

The project remains IGRATIX-1 until first-silicon submission and the associated engineering/customer evaluation work are complete.

## OPERATING RULE

Build first.

Verify continuously.

Measure.

Fix.

Checkpoint.

Move forward.

Do not turn the project into a tutorial.

Do not silently change the specification.

If a genuine architectural conflict appears, stop and report the exact conflict before changing the architecture.



# IGRATIX-1 ARCHITECTURE FREEZE CHECK

Treat the previously saved IGRATIX-1 Master Project Context as authoritative.

Before proposing implementation changes:

1. Identify the current implementation status.
2. Identify the current tape-out readiness status.
3. Compare the proposed change against the locked functional specification.
4. Check whether it changes:

   * external pins
   * register map
   * I2C behavior
   * PWM timing
   * update semantics
   * reset semantics
   * OE behavior
   * clock/reset architecture
   * synthesis assumptions
   * ASIC/PDK assumptions
5. If no real engineering problem exists, do not redesign the architecture.
6. If a conflict exists, stop and state:

   * exact conflict
   * affected modules
   * downstream consequences
   * recommended minimal correction
7. Prefer the smallest architecture that can survive synthesis, timing closure, physical design, DRC/LVS and tape-out.
8. Never silently modify the specification.

Return:

CURRENT STATUS
ARCHITECTURE STATUS
CONFLICTS
P0 BLOCKERS
NEXT CONCRETE ACTION




# RESUME IGRATIX-1 DEVELOPMENT

We are continuing the IGRATIX-1 ASIC project.

Load and obey the saved IGRATIX-1 Master Project Context.

Project objective:

16-channel, 12-bit programmable PWM controller with I2C, synchronized updates, global/group update, OE and deterministic reset, progressing toward verified RTL, synthesis, physical implementation, DRC/LVS and final GDS/tape-out.

Development mode:

FAST / PRODUCT-FIRST / TAPE-OUT-ORIENTED.

Do not re-teach basic concepts.

Do not revisit product selection.

Do not redesign working architecture without evidence.

First inspect the current repository/tool output that I provide.

Then report only:

1. IMPLEMENTED
2. VERIFIED
3. CURRENT P0 BLOCKER
4. CURRENT P1/TAPE-OUT RISK
5. NEXT EXACT ACTION

For the next action, provide the exact:

* file path
* code/content to add or modify
* command to run
* expected result
* failure interpretation
* next step after success

Do not tell me merely "implement X."

Guide me through the actual implementation one step at a time.

Never claim a test, synthesis, timing check, DRC, LVS or physical-design stage passed unless I provide actual tool evidence.

Preserve logs and reports.

Keep the architecture stable.

Do not start IGRATIX-2.
