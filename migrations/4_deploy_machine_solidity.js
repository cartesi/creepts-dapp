
const BitsManipulationLibrary = artifacts.require("@cartesi/util/BitsManipulationLibrary");

const RiscVDecoder = artifacts.require("@cartesi/machine-solidity-step/RiscVDecoder");
const ShadowAddresses = artifacts.require("@cartesi/machine-solidity-step/ShadowAddresses");
const RiscVConstants = artifacts.require("@cartesi/machine-solidity-step/RiscVConstants");
const CSRReads = artifacts.require("@cartesi/machine-solidity-step/CSRReads");
const BranchInstructions = artifacts.require("@cartesi/machine-solidity-step/BranchInstructions");
const RealTimeClock = artifacts.require("@cartesi/machine-solidity-step/RealTimeClock");
const ArithmeticInstructions = artifacts.require("@cartesi/machine-solidity-step/ArithmeticInstructions");
const ArithmeticImmediateInstructions = artifacts.require("@cartesi/machine-solidity-step/ArithmeticImmediateInstructions");
const AtomicInstructions = artifacts.require("@cartesi/machine-solidity-step/AtomicInstructions");
const S_Instructions = artifacts.require("@cartesi/machine-solidity-step/S_Instructions");
const EnvTrapInstructions = artifacts.require("@cartesi/machine-solidity-step/EnvTrapIntInstructions");
const StandAloneInstructions = artifacts.require("@cartesi/machine-solidity-step/StandAloneInstructions");

const Execute = artifacts.require("@cartesi/machine-solidity-step/Execute");
const Exceptions = artifacts.require("@cartesi/machine-solidity-step/Exceptions");
const Fetch = artifacts.require("@cartesi/machine-solidity-step/Fetch");
const PMA = artifacts.require("@cartesi/machine-solidity-step/PMA");
const CSR = artifacts.require("@cartesi/machine-solidity-step/CSR");
const CSRExecute = artifacts.require("@cartesi/machine-solidity-step/CSRExecute");
const HTIF = artifacts.require("@cartesi/machine-solidity-step/HTIF");
const CLINT = artifacts.require("@cartesi/machine-solidity-step/CLINT");
const Interrupts = artifacts.require("@cartesi/machine-solidity-step/Interrupts");

const MemoryInteractor = artifacts.require("@cartesi/machine-solidity-step/MemoryInteractor");
const VirtualMemory = artifacts.require("@cartesi/machine-solidity-step/VirtualMemory");
const Step = artifacts.require("@cartesi/machine-solidity-step/Step");

// arbitration-dlib dependency
const MMInstantiator = artifacts.require("@cartesi/arbitration/MMInstantiator");

// Read environment variable to decide if it should instantiate MM or get the address
module.exports = function(deployer) {
  //Deploy libraries
  deployer.then(async () => {
    await deployer.deploy(ShadowAddresses);
    await deployer.deploy(RiscVConstants);

    await deployer.link(BitsManipulationLibrary, RiscVDecoder);
    await deployer.deploy(RiscVDecoder);
    await deployer.deploy(RealTimeClock);

    await deployer.link(RiscVDecoder, BranchInstructions);
    await deployer.link(RiscVDecoder, ArithmeticInstructions);
    await deployer.link(RiscVDecoder, ArithmeticImmediateInstructions);
    await deployer.link(RiscVDecoder, StandAloneInstructions);
    await deployer.link(RiscVDecoder, CSRReads);

    await deployer.link(RiscVConstants, BranchInstructions);
    await deployer.link(RiscVConstants, ArithmeticInstructions);
    await deployer.link(RiscVConstants, ArithmeticImmediateInstructions);
    await deployer.link(RiscVConstants, CSRReads);
    await deployer.link(RiscVConstants, StandAloneInstructions);
    await deployer.link(RiscVConstants, EnvTrapInstructions);
    await deployer.link(BitsManipulationLibrary, ArithmeticImmediateInstructions);

    await deployer.deploy(ArithmeticInstructions);
    await deployer.deploy(ArithmeticImmediateInstructions);
    await deployer.deploy(StandAloneInstructions);
    await deployer.deploy(BranchInstructions);
    await deployer.deploy(PMA);

    await deployer.link(RealTimeClock, CSRReads);
    await deployer.deploy(CSRReads);

    //Link all libraries to CLINT
    await deployer.link(RealTimeClock, CLINT);
    await deployer.link(RiscVConstants, CLINT);
    await deployer.deploy(CLINT);

    //Link all libraries to HTIF
    await deployer.link(RealTimeClock, HTIF);
    await deployer.link(RiscVConstants, HTIF);
    await deployer.deploy(HTIF);

    //Link all libraries to CSR
    await deployer.link(RealTimeClock, CSR);
    await deployer.link(RiscVDecoder, CSR);
    await deployer.link(CSRReads, CSR);
    await deployer.link(RiscVConstants, CSR);
    await deployer.deploy(CSR);

    //Link all libraries to CRSExecute
    await deployer.link(RealTimeClock, CSRExecute);
    await deployer.link(RiscVDecoder, CSRExecute);
    await deployer.link(CSRReads, CSRExecute);
    await deployer.link(RiscVConstants, CSRExecute);
    await deployer.link(CSR, CSRExecute);
    await deployer.deploy(CSRExecute);

    //Link all libraries to Exceptions
    await deployer.link(RiscVConstants, Exceptions);
    await deployer.deploy(Exceptions);

    await deployer.link(Exceptions, EnvTrapInstructions);
    await deployer.deploy(EnvTrapInstructions);

    //Link libraries to Virtual Memory
    await deployer.link(RiscVDecoder, VirtualMemory);
    await deployer.link(ShadowAddresses, VirtualMemory);
    await deployer.link(RiscVConstants, VirtualMemory);
    await deployer.link(PMA, VirtualMemory);
    await deployer.link(CLINT, VirtualMemory);
    await deployer.link(HTIF, VirtualMemory);
    await deployer.link(Exceptions, VirtualMemory);
    await deployer.deploy(VirtualMemory);

    //Link all libraries to S_Instructions
    await deployer.link(RiscVDecoder, S_Instructions);
    await deployer.link(VirtualMemory, S_Instructions);
    await deployer.deploy(S_Instructions);

    //Link all libraries to AtomicInstruction
    await deployer.link(RiscVDecoder, AtomicInstructions);
    await deployer.link(VirtualMemory, AtomicInstructions);
    await deployer.deploy(AtomicInstructions);

    //Link all libraries to Step
    await deployer.link(RiscVDecoder, Step);
    await deployer.link(ShadowAddresses, Step);
    await deployer.link(RiscVConstants, Step);

    //Link all libraries to Fetch
    await deployer.link(RiscVDecoder, Fetch);
    await deployer.link(ShadowAddresses, Fetch);
    await deployer.link(RiscVConstants, Fetch);
    await deployer.link(PMA, Fetch);
    await deployer.link(VirtualMemory, Fetch);
    await deployer.link(Exceptions, Fetch);
    await deployer.deploy(Fetch);
    await deployer.link(Fetch, Step);

    //Link all libraries to Interrupts
    await deployer.link(ShadowAddresses, Interrupts);
    await deployer.link(RiscVConstants, Interrupts);
    await deployer.link(Exceptions, Interrupts);
    await deployer.deploy(Interrupts);
    await deployer.link(Interrupts, Step);

    // Link all libraries to MemoryInteractor
    await deployer.link(BitsManipulationLibrary, MemoryInteractor);
    await deployer.link(HTIF, MemoryInteractor);
    await deployer.link(CLINT, MemoryInteractor);
    await deployer.link(RiscVConstants, MemoryInteractor);
    await deployer.link(ShadowAddresses, MemoryInteractor);

    //Link all libraries to Execute
    await deployer.link(RiscVDecoder, Execute);
    await deployer.link(ShadowAddresses, Execute);
    await deployer.link(RiscVConstants, Execute);
    await deployer.link(BranchInstructions, Execute);
    await deployer.link(ArithmeticInstructions, Execute);
    await deployer.link(ArithmeticImmediateInstructions, Execute);
    await deployer.link(AtomicInstructions, Execute);
    await deployer.link(EnvTrapInstructions, Execute);
    await deployer.link(StandAloneInstructions, Execute);
    await deployer.link(BitsManipulationLibrary, Execute);
    await deployer.link(CSRExecute, Execute);
    await deployer.link(CSR, Execute);
    await deployer.link(Exceptions, Execute);
    await deployer.link(S_Instructions, Execute);
    await deployer.link(VirtualMemory, Execute);
    await deployer.deploy(Execute);
    await deployer.link(Execute, Step);

    await deployer.link(BitsManipulationLibrary, MemoryInteractor);
    await deployer.link(ShadowAddresses, MemoryInteractor);

    await deployer.deploy(MemoryInteractor, MMInstantiator.address);
    await deployer.deploy(Step, MemoryInteractor.address);

  });
};
