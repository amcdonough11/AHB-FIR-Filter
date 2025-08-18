USER ?= aidan
VERSION ?= 1.0.0
LIB ?= FIR_FILTER
TARGET ?= sim
WAVE_FILE_NAME ?= sim.vcd
TOOL ?= verilator # or modelsim
GTKW ?= waves/$*.gtkw
BUILD = tmp/build
SYN_TOOL = design_compiler
MS_SIM_MAKE_ROOT = tmp/build/337mg054_APB_UART_apb_uart_rx_1.0.0/sim-modelsim/
MS_SIM_MAKE_ROOT = tmp/build/337mg054_APB_UART_apb_uart_rx_1.0.0/syn_sim-modelsim/

WAVE_FILE = build/$(USER)_$(LIB)_$*_$(VERSION)/$(TARGET)-$(TOOL)/$(WAVE_FILE_NAME)

%_sim:
	@echo "Running FuseSoC for '$*'"
	fusesoc --verbose --cores-root . run --build-root $(BUILD) --setup --build --run --target=$(TARGET) $(USER):$(LIB):$*:$(VERSION)

%_simgui:
	@echo "Running simgui for '$*'"
	fusesoc --verbose --cores-root . run --build-root $(BUILD) --setup --build --target=$(TARGET) --tool modelsim $(USER):$(LIB):$*:$(VERSION)
	@$(MAKE) -C $(MS_SIM_MAKE_ROOT) run-gui

%_gtkwaves:
	@echo "Running FuseSoC for '$*'"
	fusesoc --verbose run --target=$(TARGET) $(USER):$(LIB):$*:$(VERSION)

	@echo "Looking for wave files"
	@test -s "$(WAVE_FILE)" || { \
	  echo "Wave file not found or empty: $(WAVE_FILE)"; \
	  echo "  - Did your TB call $$dumpfile(\"$(WAVE_FILE_NAME)\") and $$dumpvars?"; \
	  echo "  - For Verilator, did you enable --trace / --trace-fst in the .core?"; \
	  exit 1; \
	}

	@echo "Running gtkwave"
	gtkwave $(WAVE_FILE) -a $(GTKW)

%_syn:
	@echo "Running $(SYN_TOOL) for '$*'"
	fusesoc --cores-root . run --build-root $(BUILD) --setup --build --run --target syn --tool $(SYN_TOOL) $(USER):$(LIB):$*

%_syn_run:
	@echo "Running $(SYN_TOOL)_run for '$*'"
	fusesoc --verbose --cores-root . run --build-root $(BUILD) --run --target syn_sim --tool modelsim $(USER):$(LIB):$*

%_syn_rungui:
	fusesoc --verbose --cores-root . run --build-root $(BUILD) --target syn_sim --tool modelsim $(USER):$(LIB):$*
	@$(MAKE) -C $(MS_SYN_MAKE_ROOT) run-gui