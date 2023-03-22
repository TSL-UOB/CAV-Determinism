# CAV-Determinism
This is the official repository for our paper: [On Determinism of Game Engines Used for Simulation-Based Autonomous Vehicle Verification](https://ieeexplore.ieee.org/document/9793395)
The repo contains python scripts for running experiments in CARLA and matlab code for post-processing outputs. 

## Abstract
Game engines are increasingly used as simulation platforms by the autonomous vehicle community to develop vehicle control systems and test environments. A key requirement for simulation-based development and verification is determinism, since a deterministic process will always produce the same output given the same initial conditions and event history. Thus, in a deterministic simulation environment, tests are rendered repeatable and yield simulation results that are trustworthy and straightforward to debug. However, game engines are seldom deterministic. This paper reviews and identifies the potential causes and effects of non-deterministic behaviours in game engines. A case study using CARLA, an open-source autonomous driving simulation environment powered by Unreal Engine, is presented to highlight its inherent shortcomings in providing sufficient precision in experimental results. Different configurations and utilisations of the software and hardware are explored to determine an operational domain where the simulation precision is sufficiently high i.e. variance between repeated executions becomes negligible for development and testing work. Finally, a method of a general nature is proposed, that can be used to find the domains of permissible variance in game engine simulations for any given system configuration.
