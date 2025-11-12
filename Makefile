.PHONY: ansible-ping ansible-playbook ansible-playbook-apply ansible-adhoc ansible-list-hosts ansible-lint

ANSIBLE_DIR := ansible
ANSIBLE_CFG := $(ANSIBLE_DIR)/ansible.cfg
ANSIBLE_INVENTORY := inventory.yml
ANSIBLE_HOST := edu-gpu

ansible-ping:
	@cd $(ANSIBLE_DIR) && ansible $(ANSIBLE_HOST) -m ping

ansible-list-hosts:
	@cd $(ANSIBLE_DIR) && ansible-inventory --list

ansible-playbook:
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo "Error: Please specify PLAYBOOK variable. Example: make ansible-playbook PLAYBOOK=playbook.yml"; \
		exit 1; \
	fi
	@cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INVENTORY) --check $(PLAYBOOK)

ansible-playbook-apply:
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo "Error: Please specify PLAYBOOK variable. Example: make ansible-playbook-apply PLAYBOOK=playbook.yml"; \
		exit 1; \
	fi
	@cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INVENTORY) $(PLAYBOOK)

ansible-adhoc:
	@if [ -z "$(MODULE)" ] || [ -z "$(ARGS)" ]; then \
		echo "Error: Please specify MODULE and ARGS variables. Example: make ansible-adhoc MODULE=shell ARGS='uptime'"; \
		exit 1; \
	fi
	@cd $(ANSIBLE_DIR) && ansible $(ANSIBLE_HOST) -m $(MODULE) -a "$(ARGS)"

ansible-gather-facts:
	@cd $(ANSIBLE_DIR) && ansible $(ANSIBLE_HOST) -m setup

ansible-lint:
	@cd $(ANSIBLE_DIR) && ansible-lint $(if $(PLAYBOOK),$(PLAYBOOK),.)
