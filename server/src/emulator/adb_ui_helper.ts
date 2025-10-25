import * as cheerio from "cheerio";
import { exec } from "child_process";
import { KeyboardEvent, KeyboardEvent_KeyEventType, TouchEvent, type EmulatorControllerClient } from "./emulator_controller";
import type { CssQueryBuilder } from "../utils/css_query_builder";
import type { CheerioAPI, Cheerio } from "cheerio";

export class UiAutomatorHelper {
    constructor(private androidClient: EmulatorControllerClient) { }

    captureLayout = async () => {
        return new Promise<CheerioAPI>((resolve, reject) => {
            exec("adb shell uiautomator dump /sdcard/window_dump.xml && adb exec-out cat /sdcard/window_dump.xml", async (err, stdout) => {
                const $ = cheerio.load(stdout.split('/sdcard/window_dump.xml')[1]!, { xmlMode: true });
                if (err) return reject(err);
                resolve($);
            });
        });
    }

    getNode = async (query: CssQueryBuilder) => {
        const $ = await this.captureLayout();
        return $(query.build());
    }

    getNodeBounds = async (node: Cheerio<any>) => {
        const bounds = JSON.parse(`[${node.attr('bounds')!.split('][').join('],[')}]`);
        const boundsMap = {
            left: bounds[0][0],
            top: bounds[0][1],
            right: bounds[1][0],
            bottom: bounds[1][1],
            center: {
                x: Math.floor((bounds[0][0] + bounds[1][0]) / 2),
                y: Math.floor((bounds[0][1] + bounds[1][1]) / 2),
            }
        };

        return boundsMap;
    }

    tap = async ({ x, y, pressure, display }: { x: number, y: number, display?: number, pressure?: number }) => {
        return new Promise<void>((resolve, reject) => {
            this.androidClient.sendTouch(TouchEvent.create({
                touches: [
                    {
                        x: x,
                        y: y,
                        pressure: pressure ?? 1,
                    }
                ],
                display: display ?? 0
            }), (err, data) => {
                if (err) return reject(err);
                resolve();
            });
        });
    }

    endTap = async ({ x, y, interval, display }: { x: number, y: number, interval?: number, display?: number }) => {
        return this.runAfterDelay(interval ?? 100, async () => {
            await this.tap({ x, y, pressure: 0, display });
        });
    }

    tapAt = async ({ x, y, interval, pressure, display }: { x: number, y: number, interval?: number, pressure?: number, display?: number }) => {
        await this.tap({ x, y, pressure, display });
        await this.endTap({ x, y, interval, display });
    }

    scroll = async ({ startX, startY, endX, endY, duration }: { startX: number, startY: number, endX: number, endY: number, duration?: number }) => {
        await this.tap({ x: startX, y: startY, pressure: 1, display: 0 });
        this.runAfterDelay(duration ?? 100, async () => {
            await this.tap({ x: endX, y: endY, pressure: 1, display: 0 });
        });
        await this.endTap({ x: endX, y: endY, interval: duration ?? 300, display: 0 });
    }

    runAfterDelay = async (delay: number, fn: () => Promise<void>) => {
        return new Promise<void>((resolve, reject) => {
            setTimeout(async () => {
                await fn();
                resolve();
            }, delay);
        });
    }

    charToKeyCode(char: string): number {
        const code = char.toUpperCase().charCodeAt(0);
        if (code >= 65 && code <= 90) return 29 + (code - 65); // KEYCODE_A = 29
        if (code >= 48 && code <= 57) return 7 + (code - 48);   // KEYCODE_0 = 7
        throw new Error("Unsupported character: " + char);
    }

    typeString = async (text: string) => {
        await new Promise<void>(async (resolve, reject) => {
            for (const c of text) {
                const keyCode = this.charToKeyCode(c);
                this.androidClient.sendKey(KeyboardEvent.create({ keyCode, eventType: KeyboardEvent_KeyEventType.keypress }), (err, data) => {
                    if (err) return reject(err);
                });
            }
            resolve();
        });
    }

    typeTextADB = async (text: string) => {
        return new Promise<void>((resolve, reject) => {
            exec(`adb shell input text '${text.replace(/ /g, '%s')}'`, (err, stdout, stderr) => {
                if (err) {
                    console.error("Error typing text via ADB:", err);
                    return reject(err);
                }
                resolve();
            });
        });
    }
}