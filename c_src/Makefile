# -------------------------------------------------------------------
#
# Copyright (c) 2012-2017 Basho Technologies, Inc.
# Copyright (c) 2017-2023 Workday, Inc.
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

# Where the sub-repos come from should all be overridden on the command line or
# in exported environment variables, either globally or per-repo.
# The defaults here WILL NOT work, they're just placeholders.
DFLT_REPO_PROJECT ?= https://github.com/basho
DFLT_REPO_BRANCH  ?= develop-3.0
# Per-repo overrides
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

BASEDIR := $(shell pwd)
PRIVDIR := $(abspath $(BASEDIR)/..)/priv

TOOLS := leveldb_repair perf_dump sst_rewrite sst_scan
LDB_TOOLS := $(patsubst %,$(BASEDIR)/leveldb/%,$(TOOLS))
TGT_TOOLS := $(patsubst %,$(PRIVDIR)/%,$(TOOLS))
TARGETS := $(BASEDIR)/leveldb/libleveldb.a \
	$(BASEDIR)/system/lib/libsnappy.a $(TGT_TOOLS)

# snappy requires cmake v3 - default on current Macs, but may have a suffix
# when installed as a package on other platforms.
CMAKE := $(shell command -v cmake3 2>/dev/null || command -v cmake)
CPX := /bin/cp -p

LDFLAGS := $(LDFLAGS) -L$(BASEDIR)/system/lib
CFLAGS := $(CFLAGS) -I $(BASEDIR)/system/include -I. -I $(BASEDIR)/leveldb/include -fPIC
CXXFLAGS := $(CXXFLAGS) -I $(BASEDIR)/system/include -I. -I $(BASEDIR)/leveldb/include -fPIC
TEST_CXXFLAGS := $(CXXFLAGS) -Wno-narrowing

ifeq ($(shell uname -s),Darwin)
	CPX := /bin/cp -pX
	# Resolves C++11 narrowing error on Mac OS
	TEST_CXXFLAGS += -Wno-c++11-narrowing
endif

.PHONY: clean compile get-deps test

compile: $(TARGETS)

get-deps: $(BASEDIR)/leveldb $(BASEDIR)/snappy

$(BASEDIR)/leveldb:
	git clone $(LEVELDB_CLONE_ARGS) $(LDB_EE_PROJECT)/leveldb.git $@
	git clone $(LDB_EE_CLONE_ARGS) $(SUB_REPO_PROJECT)/leveldb_ee.git $@/leveldb_ee

$(BASEDIR)/snappy:
	git clone $(SNAPPY_CLONE_ARGS) $(SNAPPY_PROJECT)/snappy.git $@

# This gets built after the repo's cloned but before tools, so get the version
# set up - the leveldb makefile will re-use the config script once it's created
# here, so no need to do it again later.
$(BASEDIR)/leveldb/libleveldb.a: $(BASEDIR)/leveldb $(BASEDIR)/system/lib/libsnappy.a
	LEVELDB_VSN=$(shell git --git-dir=$(BASEDIR)/leveldb/.git \
		describe --tags | grep -Eo '^[0-9\.]+' \
	) $(MAKE) LDFLAGS="$(LDFLAGS) -lsnappy" -C $(BASEDIR)/leveldb all

$(TGT_TOOLS) &: $(BASEDIR)/leveldb/libleveldb.a
	$(MAKE) LDFLAGS="$(LDFLAGS) -lsnappy -lpthread" -C $(BASEDIR)/leveldb tools
	$(CPX) $(LDB_TOOLS) $(PRIVDIR)

$(BASEDIR)/system/lib/libsnappy.a: $(BASEDIR)/snappy
	/bin/mkdir -p $(BASEDIR)/snappy/build $(BASEDIR)/system
	( cd $(BASEDIR)/snappy/build && \
		$(CMAKE) -D SNAPPY_BUILD_TESTS=0 -D SNAPPY_BUILD_BENCHMARKS=0 \
		-D CMAKE_INSTALL_PREFIX=$(BASEDIR)/system .. && \
		$(MAKE) && \
		$(MAKE) install )
	/bin/test -d $(BASEDIR)/system/lib || \
		/bin/mv $(BASEDIR)/system/lib64 $(BASEDIR)/system/lib
	/bin/rm -rf $(BASEDIR)/snappy/build $(BASEDIR)/system/lib/cmake

clean:
	$(MAKE) -C $(BASEDIR)/leveldb clean
	/bin/rm -rf system

test: compile
	$(MAKE) CXXFLAGS="$(TEST_CXXFLAGS)" \
		LDFLAGS="$(LDFLAGS) -lsnappy -lpthread" -C $(BASEDIR)/leveldb test
