SUDO = sudo
PODMAN = $(SUDO) podman

MAJOR = 10-kitten
VARIANT = gnome
ARCH = x86_64
IMAGE_NAME ?= localhost/almalinux-$(VARIANT)
IMAGE_TAG ?= latest
SOURCE_IMAGE_REF ?= $(IMAGE_NAME):$(IMAGE_TAG)
IMAGE_TYPE ?= iso
IMAGE_CONFIG ?= iso.toml
UPDATE_IMAGE_REF ?= localhost/almalinux-$(VARIANT):$(IMAGE_TAG)

QEMU_DISK_RAW ?= ./output/disk.raw
QEMU_DISK_QCOW2 ?= ./output/qcow2/disk.qcow2
QEMU_ISO ?= ./output/bootiso/install.iso


.ONESHELL:

bootc:
	sudo bluebuild build ./recipes/recipe.yml

image:
	rm -rf ./output
	mkdir -p ./output

	cp $(IMAGE_CONFIG) ./output/config.toml
	# If we're not running on a github action, we need to set a real quay.io image ref
	if [ -z "$(GITHUB_SHA)" ]; then
		cat << EOF >> ./output/config.toml

	[customizations.installer.kickstart]
	# When things are signed, add --erroronfail to %post
	contents = """
	%post --log=/root/anaconda-post.log
	bootc switch --mutate-in-place --transport registry --enforce-container-sigpolicy ${UPDATE_IMAGE_REF}

	%end
	"""
	EOF
	fi

	cat ./output/config.toml

	@# AlmaLinux's repos are configured with mirrorlist and apparently that stops you from building ISOs with librepo=true
	@# https://github.com/osbuild/bootc-image-builder/issues/883
	if [ "$(IMAGE_TYPE)" = "iso" ]; then
		LIBREPO=False;
	else
		LIBREPO=True;
	fi;
	$(PODMAN) run \
		--rm \
		-it \
		--privileged \
		--pull=newer \
		--security-opt label=type:unconfined_t \
		-v ./output:/output \
		-v ./output/config.toml:/config.toml:ro \
		-v /var/lib/containers/storage:/var/lib/containers/storage \
		quay.io/centos-bootc/bootc-image-builder:latest \
		--type $(IMAGE_TYPE) \
		--use-librepo=$$LIBREPO \
		$(SOURCE_IMAGE_REF)

	$(SUDO) chown -R $(USER):$(USER) ./output

image-iso:
	make image IMAGE_TYPE=iso

image-qcow2:
	make image IMAGE_TYPE=qcow2

run-qemu-qcow:
	qemu-system-x86_64 \
		-M accel=kvm \
		-cpu host \
		-smp 2 \
		-m 4096 \
		-bios /usr/share/OVMF/x64/OVMF.4m.fd \
		-serial stdio \
		-snapshot $(QEMU_DISK_QCOW2)

run-qemu-iso:
	# Make a disk to install to
	[[ ! -e $(QEMU_DISK_RAW) ]] && dd if=/dev/null of=$(QEMU_DISK_RAW) bs=1M seek=10240

	qemu-system-x86_64 \
		-M accel=kvm \
		-cpu host \
		-smp 2 \
		-m 4096 \
		-bios /usr/share/OVMF/x64/OVMF.4m.fd \
		-serial stdio \
		-boot d \
		-cdrom $(QEMU_ISO) \
		-hda $(QEMU_DISK_RAW)
