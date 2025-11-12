ANSIBLE_DIR := ansible
ANSIBLE_CFG := $(ANSIBLE_DIR)/ansible.cfg
ANSIBLE_INVENTORY := inventory.yml
ANSIBLE_HOST := edu-gpu
SSH_HOST := edu-gpu
SSH_CONFIG := $(ANSIBLE_DIR)/ssh_config

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
	@cd $(ANSIBLE_DIR) && ansible-playbook -i $(ANSIBLE_INVENTORY) $(PLAYBOOK)

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
	@ssh -F "$(SSH_CONFIG)" -l r03i23 -L "$(PORT):localhost:$(PORT)" -N -f "$(SSH_HOST)"

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

.PHONY: encrypt-edu-gpu-kind-portforward
encrypt-edu-gpu-kind-portforward:
	sops --encrypt --output kubeconfig/edu-gpu-kind-portforward.sops.yaml kubeconfig/edu-gpu-kind-portforward.yaml

.PHONY: decrypt-edu-gpu-kind-portforward
decrypt-edu-gpu-kind-portforward:
	sops --decrypt --output kubeconfig/edu-gpu-kind-portforward.yaml kubeconfig/edu-gpu-kind-portforward.sops.yaml
