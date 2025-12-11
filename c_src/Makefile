# -------------------------------------------------------------------
#
# Copyright (c) 2012-2017 Basho Technologies, Inc.
# Copyright (c) 2017-2025 Workday, Inc.
#
# This file is provided to you under the Apache License,
# Version 2.0 (the "License"); you may not use this file
# except in compliance with the License.  You may obtain
# a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# -------------------------------------------------------------------
#
# Derived from and replacement for build_deps.sh, which always should have
# been a makefile.
#
# Now, the leveldb, leveldb_ee, and snappy repositories are cloned from
# GitHub (by default) rather than being submodules or archives.
#
# Sub-package checkouts are from the head of the relevant branch in the
# cloned sub-package instead of by 'version'.
#
# This approach eases maintenance and ingestion into development and release
# build processes.
#
# To avoid spurious rebuilds (as when building devrels, or rebuilding in the
# same tree during iterative development), most transitive dependencies are
# NOT Makefile targets, making the build pretty much an all-or-nothing process.
# This isn't a problem because we only want to build once then re-use the
# result.
#
# In further support of our higher-level targets, we clean out *some* interim
# files and unneeded cruft as part of the build process so we can later package
# up only what we need. It remains to be seen how much of that should be done
# here and how much should be in external build scripts.
#
BASEDIR := $(shell pwd)
#
# Where the sub-repos come from should be overridden by one of the following:
# - on the command line
# - in exported environment variables
# - in the file 'Subrepo.mk' in this repo's root
# Overrides can be global, per-repo, or a combination of the two.
#
SUBREPO_SPECS := $(abspath $(BASEDIR)/..)/Subrepo.mk
ifneq ($(wildcard $(SUBREPO_SPECS)),)
include $(SUBREPO_SPECS)
endif
# Defaults for all overrideable sub-repo sources follow.
# Do NOT change them here, see above to override.

# Defaults for all sub-repos.
DFLT_REPO_PROJECT ?= https://github.com/OpenRiak
DFLT_REPO_BRANCH  ?= openriak-3.4
# Per-repo overrides.
LEVELDB_PROJECT ?= $(DFLT_REPO_PROJECT)
LEVELDB_BRANCH  ?= $(DFLT_REPO_BRANCH)
LDB_EE_PROJECT  ?= $(DFLT_REPO_PROJECT)
LDB_EE_BRANCH   ?= $(DFLT_REPO_BRANCH)
SNAPPY_PROJECT  ?= $(DFLT_REPO_PROJECT)
SNAPPY_BRANCH   ?= $(DFLT_REPO_BRANCH)
# These should never need to be overridden ... but you can if you must.
LEVELDB_CLONE_ARGS  ?= --single-branch --branch $(LEVELDB_BRANCH)
LDB_EE_CLONE_ARGS   ?= --single-branch --branch $(LDB_EE_BRANCH)
SNAPPY_CLONE_ARGS   ?= --single-branch --branch $(SNAPPY_BRANCH)

PRIVDIR := $(abspath $(BASEDIR)/..)/priv

TOOLS := leveldb_repair perf_dump sst_rewrite sst_scan
LDB_TOOLS := $(patsubst %,$(BASEDIR)/leveldb/%,$(TOOLS))
TGT_TOOLS := $(patsubst %,$(PRIVDIR)/%,$(TOOLS))
TARGETS := $(BASEDIR)/leveldb/libleveldb.a \
	$(BASEDIR)/system/lib/libsnappy.a $(TGT_TOOLS)

# snappy requires cmake v3+ - the default (when installed) on newer OSes,
# but may have a suffix on older ones.
# Since it's an add-on on most platforms make sure the value doesn't wind
# up blank, so there's a meaningful error message if it's not installed.
CMAKE := $(shell command -v cmake3 2>/dev/null || \
	command -v cmake 2>/dev/null || echo cmake)
# Copy with timestamps, without EAs, overridden per-OS
CPX := /bin/cp -p
# We want the full path shown in the output, or a meaningful error message
# if it's not installed.
GIT := $(shell command -v git 2>/dev/null || echo git)

# Flags in addition to those the LevelDB build will figure out for itself.
# These are just to let it find and use Snappy.
CFLAGS += -I$(BASEDIR)/system/include
CXXFLAGS += -I$(BASEDIR)/system/include
LDFLAGS += -L$(BASEDIR)/system/lib
TEST_CXXFLAGS := $(CXXFLAGS) -Wno-narrowing

ifeq ($(shell uname -s),Darwin)
	CPX := /bin/cp -pX
	# Resolves C++11 narrowing error on macOS
	TEST_CXXFLAGS += -Wno-c++11-narrowing
endif

.PHONY: clean compile distclean get-deps test

compile: $(TARGETS)

get-deps: $(BASEDIR)/leveldb $(BASEDIR)/snappy

$(BASEDIR)/leveldb:
	$(GIT) clone $(LEVELDB_CLONE_ARGS) $(DFLT_REPO_PROJECT)/leveldb.git $@
	$(GIT) clone $(LDB_EE_CLONE_ARGS) $(LDB_EE_PROJECT)/leveldb_ee.git $@/leveldb_ee

$(BASEDIR)/snappy:
	$(GIT) clone $(SNAPPY_CLONE_ARGS) $(SNAPPY_PROJECT)/snappy.git $@

# This gets built after the repo's cloned but before tools, so get the version
# set up - the leveldb makefile will re-use the config script once it's created
# here, so no need to do it again later.
# Flags need to be in the shell environment, not just on the $(MAKE) command line,
# so that leveldb/build_detect_platform picks them up.
$(BASEDIR)/leveldb/libleveldb.a: $(BASEDIR)/leveldb $(BASEDIR)/system/lib/libsnappy.a
	LEVELDB_VSN=$(shell $(GIT) --git-dir=$(BASEDIR)/leveldb/.git \
		describe --tags | grep -Eo '^[0-9\.]+' ) \
	CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
	$(MAKE) -C $(BASEDIR)/leveldb all

$(TGT_TOOLS) &: $(BASEDIR)/leveldb/libleveldb.a
	CFLAGS="$(CFLAGS)" CXXFLAGS="$(CFLAGS)" LDFLAGS="$(LDFLAGS)" \
	$(MAKE) -C $(BASEDIR)/leveldb tools
	$(CPX) $(LDB_TOOLS) $(PRIVDIR)

$(BASEDIR)/system/lib/libsnappy.a: $(BASEDIR)/snappy
	/bin/mkdir -p $(BASEDIR)/snappy/build $(BASEDIR)/system
	$(CMAKE) \
		-S $(BASEDIR)/snappy \
		-B $(BASEDIR)/snappy/build \
		--install-prefix $(BASEDIR)/system \
		-D CMAKE_CXX_FLAGS='-fPIC -O3' \
		-D SNAPPY_BUILD_TESTS=0 -D SNAPPY_BUILD_BENCHMARKS=0 \
		-D CMAKE_POLICY_VERSION_MINIMUM=3.5
	VERBOSE=1 $(MAKE) -C $(BASEDIR)/snappy/build
	VERBOSE=1 $(MAKE) -C $(BASEDIR)/snappy/build install
	/bin/test -d $(BASEDIR)/system/lib || \
		/bin/ln -s lib64 $(BASEDIR)/system/lib

clean:
	$(MAKE) -C $(BASEDIR)/leveldb clean
	$(MAKE) -C $(BASEDIR)/snappy/build clean
	/bin/rm -rf $(BASEDIR)/system

distclean:
	/bin/rm -rf $(TGT_TOOLS) \
		$(BASEDIR)/leveldb $(BASEDIR)/snappy $(BASEDIR)/system

test: compile
	CFLAGS="$(CFLAGS)" CXXFLAGS="$(TEST_CXXFLAGS)" LDFLAGS="$(LDFLAGS)" \
	$(MAKE) -C $(BASEDIR)/leveldb test
