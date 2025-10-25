import grpc from "@grpc/grpc-js";
import { EmulatorControllerClient } from "./emulator_controller";
import { exec } from "child_process";

const EMULATOR_PATH = process.env.EMULATOR_PATH || "C:/Users/%USERNAME%/AppData/Local/Android/Sdk/emulator/emulator";

/**
 * Get an instance of the Android Emulator gRPC client.
 * @param port The android emulator rpc client port
 * @returns An instance of the `EmulatorControllerClient`
 */
export const getAndroidClient = (port:number = 8554) => {
  return new EmulatorControllerClient(
    `localhost:${port}`,
    grpc.credentials.createInsecure()
  );
};

/**
 * Get a list of available Android Virtual Devices (AVDs).
 * @returns A promise that resolves to an array of AVD names.
 */
export const getAvailableAVDs = async (): Promise<string[]> => {
  return new Promise((resolve, reject) => {
    exec(`${EMULATOR_PATH} -list-avds`, (err, stdout) => {
      if (err) {
        console.error("Error getting available AVDs:", err);
        return reject(err);
      }
      const devices = stdout.trim()
        .split("\n");
      resolve(devices);
    });
  });
};