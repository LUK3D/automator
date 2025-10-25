import Elysia, { t } from "elysia";
import { getAndroidClient } from "./emulator";
import { ImageFormat, ImageFormat_ImgFormat, KeyboardEvent, TouchEvent } from "./emulator/emulator_controller";
import { Empty } from "./emulator/google/protobuf/empty";
import { UiAutomatorHelper } from "./emulator/adb_ui_helper";
import { CssQueryBuilder } from "./utils/css_query_builder";

let clients: string[] = [];
const androidClient = getAndroidClient();

const format = ImageFormat.create({
    format: ImageFormat_ImgFormat.PNG,
});

let stream = androidClient.streamScreenshot(format);

const uiAutomatorHelper = new UiAutomatorHelper(androidClient);

export const websocket = new Elysia()
    .get("/ui-tree", async () => {
        const node = await uiAutomatorHelper.getNode(new CssQueryBuilder('node').like('text', 'Search Google'));
        const bounds = await uiAutomatorHelper.getNodeBounds(node);
        console.log(bounds);
        await uiAutomatorHelper.tapAt({
            ...bounds.center,
            pressure: 1,
        });
    })
    .ws("/ws", {
        open(ws) {
            if (stream.closed) {
                stream = androidClient.streamScreenshot(format);
            }
            clients.push(ws.id);
            stream.on("data", (frame: any) => {
                const imageData = Buffer.from(frame.image, "base64");
                ws.send(imageData);
            });

            stream.on("error", (err: any) => {
                console.error("gRPC stream error:", err);
            });

            stream.on("end", () => {
                console.log("gRPC stream ended");
            });

            androidClient.getDisplayConfigurations(Empty.create({}), (err, data) => {
                console.log("Display configurations:", data);
                ws.send({ type: 'displays', data: data })
            })
        },
        message(ws, data: Record<string, any>) {
            const command = data['command'];
            if (command === 'tap') {
                androidClient.sendTouch(TouchEvent.create({
                    touches: [
                        {
                            x: data.x,
                            y: data.y,
                            pressure: data.pressure ?? 1,

                        },
                    ],
                    display: 0,
                }), (err, data) => {
                    if (data) {
                        console.log("Touch event response:", data);
                    }
                })

            }
        },
        close(ws) {
            clients = clients.filter(client => client !== ws.id);

            if (clients.length === 0) {
                stream.cancel();
                console.log("No clients connected, gRPC stream cancelled.");
            }
            console.log(`WebSocket connection closed: ${ws.id}`);
        }
    });

setTimeout(() => {
    console.log("Sending KEYCODE_MENU to wake up the emulator");
    androidClient.sendKey(KeyboardEvent.create({
        keyCode: 82,
    }), (err, data) => {

    });
}, 1000);