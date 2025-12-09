ANSIBLE_DIR := ansible
ANSIBLE_CFG := $(ANSIBLE_DIR)/ansible.cfg
ANSIBLE_INVENTORY := inventory.yml
ANSIBLE_HOST := edu-gpu
SSH_HOST := edu-gpu
SSH_CONFIG := $(ANSIBLE_DIR)/ssh_config
TAGS := all

.PHONY: ansible-ping
ansible-ping:
	@cd $(ANSIBLE_DIR) && ansible $(ANSIBLE_HOST) -m ping

.PHONY: ansible-list-hosts
ansible-list-hosts:
	@cd $(ANSIBLE_DIR) && ansible-inventory --list

.PHONY: ansible-playbook
ansible-playbook:
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo "Error: Please specify PLAYBOOK variable. Example: make ansible-playbook PLAYBOOK=playbook.yml"; \
		exit 1; \
	fi
	@cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INVENTORY) --check $(PLAYBOOK)

.PHONY: ansible-playbook-apply
ansible-playbook-apply:
	@if [ -z "$(PLAYBOOK)" ]; then \
		echo "Error: Please specify PLAYBOOK variable. Example: make ansible-playbook-apply PLAYBOOK=playbook.yml"; \
		exit 1; \
	fi
	@cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INVENTORY) $(PLAYBOOK) --tags $(TAGS)

.PHONY: ansible-adhoc
ansible-adhoc:
	@if [ -z "$(MODULE)" ] || [ -z "$(ARGS)" ]; then \
		echo "Error: Please specify MODULE and ARGS variables. Example: make ansible-adhoc MODULE=shell ARGS='uptime'"; \
		exit 1; \
	fi
	@cd $(ANSIBLE_DIR) && ansible $(ANSIBLE_HOST) -m $(MODULE) -a "$(ARGS)"

.PHONY: ansible-gather-facts
ansible-gather-facts:
	@cd $(ANSIBLE_DIR) && ansible $(ANSIBLE_HOST) -m setup

.PHONY: ansible-lint
ansible-lint:
	@cd $(ANSIBLE_DIR) && ansible-lint $(if $(PLAYBOOK),$(PLAYBOOK),.)

.PHONY: ssh-forward
ssh-forward:
	@if [ -z "$(PORT)" ]; then \
		echo "Error: Please specify PORT variable. Example: make ssh-forward PORT=8080"; \
		exit 1; \
	fi
	@cd $(ANSIBLE_DIR) && ssh -F "../$(SSH_CONFIG)" -l r03i23 -L "$(PORT):localhost:$(PORT)" -N -f "$(SSH_HOST)"

.PHONY: terraform-init
terraform-init:
	cd terraform && terraform init

.PHONY: terraform-plan
terraform-plan: terraform-init
	cd terraform && terraform plan

.PHONY: terraform-apply
terraform-apply: terraform-init
	cd terraform && terraform apply

.PHONY: terraform-lint
terraform-lint: terraform-init
	cd terraform && tflint

.PHONY: terraform-fmt
terraform-fmt:
	cd terraform && terraform fmt -recursive

.PHONY: sops-encrypt
sops-encrypt:
	@echo "Encrypting with SOPS..."; \
	if [ -n "$(FILE)" ]; then \
		if [ -f "$(FILE)" ] && [ "$${FILE##*.}" != "sops" ]; then FILES="$(FILE)"; \
		elif [ -f "$(FILE)" ] && [ "$${FILE##*.}" = "sops" ]; then base="$${FILE%.sops}"; if [ -f "$$base" ]; then FILES="$$base"; else echo "Error: plaintext $$base not found for $(FILE)" >&2; exit 1; fi; \
		elif [ -f "$(FILE).sops" ]; then base="$(FILE)"; if [ -f "$$base" ]; then FILES="$$base"; else echo "Error: plaintext $$base not found (got $(FILE).sops)" >&2; exit 1; fi; \
		else echo "Error: $(FILE) not found" >&2; exit 1; fi; \
	else \
		FILES="$$(find . -name "*.secrets.*" -type f ! -name "*.sops")"; \
	fi; \
	for file in $$FILES; do \
		echo "Encrypting $$file..."; \
		sops --output-type json --encrypt "$$file" > "$$file.sops"; \
	done

.PHONY: sops-decrypt
sops-decrypt:
	@echo "Decrypting with SOPS..."; \
	if [ -n "$(FILE)" ]; then \
		if [ -f "$(FILE)" ]; then FILES="$(FILE)"; \
		elif [ -f "$(FILE).sops" ]; then FILES="$(FILE).sops"; \
		else echo "Error: $(FILE) or $(FILE).sops not found" >&2; exit 1; fi; \
	else \
		FILES="$$(find . -name "*.secrets.*.sops" -type f)"; \
	fi; \
	for file in $$FILES; do \
		echo "Decrypting $$file..."; \
		base="$${file%.sops}"; \
		ext="$${base##*.}"; \
		case "$$ext" in \
		  yaml|yml) output_type="yaml" ;; \
		  *) output_type="binary" ;; \
		esac; \
		if [ -f "$$base" ]; then chmod +w "$$base"; fi; \
		sops --decrypt --output-type "$$output_type" "$$file" > "$$base"; \
		chmod -w "$$base"; \
	done

.PHONY: sops-ci
sops-ci:
	@echo "Checking for unencrypted secrets tracked by git..."; \
	FILES="$$(find . -name '*.secrets.*' ! -name '*.secrets.*.sops' -type f)"; \
	EXIT=0; \
	for file in $$FILES; do \
		if git ls-files --error-unmatch "$$file" >/dev/null 2>&1; then \
			echo "Error: Unencrypted secrets file tracked by git: $$file" >&2; \
			EXIT=1; \
		fi; \
	done; \
	if [ $$EXIT -ne 0 ]; then \
		echo "One or more unencrypted secrets files are tracked by git. Please remove them from version control." >&2; \
		exit 1; \
	fi
