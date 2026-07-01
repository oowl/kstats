cmake_minimum_required(VERSION 3.16)
project(kstats VERSION 1.0.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ── ECM / KDE CMake modules ───────────────────────────────────────────────────
find_package(ECM 6.0.0 REQUIRED NO_MODULE)
set(CMAKE_MODULE_PATH ${ECM_MODULE_PATH})

include(KDEInstallDirs6)
include(KDECMakeSettings)
include(FeatureSummary)

# ── Required KDE frameworks ────────────────────────────────────────────────────
find_package(KF6 REQUIRED COMPONENTS Package)
find_package(Plasma REQUIRED)

# ── Install the plasmoid package ───────────────────────────────────────────────
plasma_install_package(package org.kde.kstats)

feature_summary(WHAT ALL FATAL_ON_MISSING_REQUIRED_PACKAGES)
