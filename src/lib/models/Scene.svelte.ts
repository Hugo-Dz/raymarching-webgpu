// Shaders
import webgpuPipelineShader from "$lib/shaders/webgpuPipeline.wgsl";

// Models
import { UniformBuffer } from "$lib/models/UniformBuffer.svelte";

// Types
interface Uniforms {
	mouseClickData: number;
	smoothValue: number;
	time: number;
	aspectRatio: number;
	cameraPosition: [number, number, number, number]; // vec4<f32>
	shape1: number;
	shape2: number;
	operation: number;
	_padding: number;
}

class Scene {
	time = $state(0);
	isMouseDown: 0 | 1 = $state(0);
	azimuth = $state(Math.PI / 2);
	polar = $state(Math.PI / 2);
	distanceToScene = $state(6.0);
	smoothValue = $state(0.2);
	shape1 = $state(0);
	shape2 = $state(2);
	operation = $state(0);
	speed = $state(0.5);
	cameraPosition: [number, number, number, number] = $state([0, 0, this.distanceToScene, 0]);
	canvas: HTMLCanvasElement | null = $state(null);
	aspectRatio: number | null = $state(null);
	isWebGPUSupported = $state(true);

	constructor() {}

	private createCanvas(rootElement: HTMLElement) {
		const canvas = document.createElement("canvas");
		rootElement.appendChild(canvas);
		canvas.style.width = "100%";
		canvas.style.height = "100%";
		return canvas;
	}

	public async init(canvasEl: HTMLDivElement) {
		this.canvas = this.createCanvas(canvasEl);
		this.aspectRatio = this.canvas.clientWidth / this.canvas.clientHeight;

		const { device, context, presentationFormat } = await this.initWebGPU();

		const module = device.createShaderModule({
			code: webgpuPipelineShader,
		});

		// Uniforms setup
		const uniformsData: Uniforms = {
			mouseClickData: 0,
			smoothValue: this.smoothValue,
			time: 0,
			aspectRatio: this.aspectRatio,
			cameraPosition: this.cameraPosition, // vec4<f32>
			shape1: this.shape1,
			shape2: this.shape2,
			operation: this.operation,
			_padding: 0,
		};
		const bufferData = new Float32Array([
			uniformsData.mouseClickData,
			uniformsData.smoothValue,
			uniformsData.time,
			uniformsData.aspectRatio,
			...uniformsData.cameraPosition,
			uniformsData.shape1,
			uniformsData.shape2,
			uniformsData.operation,
			uniformsData._padding,
		]);
		const uniformBuffer = new UniformBuffer(device, bufferData, {
			type: "uniform",
			hasDynamicOffset: false,
			minBindingSize: bufferData.byteLength,
		});
		const pipeline = this.createPipeline(device, presentationFormat, module, [uniformBuffer.layout]);

		const render = () => {
			const renderPassDescriptor = {
				colorAttachments: [
					{
						view: context.getCurrentTexture().createView(),
						clearValue: [0.0, 0.0, 0.0, 1],
						loadOp: "clear",
						storeOp: "store",
					},
				],
			} as GPURenderPassDescriptor;

			const commandEncoder = device.createCommandEncoder();
			const pass = commandEncoder.beginRenderPass(renderPassDescriptor);
			pass.setPipeline(pipeline);
			pass.setBindGroup(0, uniformBuffer.bindGroup);
			pass.draw(6);
			pass.end();
			device.queue.submit([commandEncoder.finish()]);

			uniformBuffer.update(
				new Float32Array([
					this.isMouseDown,
					this.smoothValue * 2,
					(this.time += 0.016 * this.speed),
					this.aspectRatio ?? 1.0,
					...this.cameraPosition,
					this.shape1,
					this.shape2,
					this.operation,
					uniformsData._padding,
				])
			);

			requestAnimationFrame(render);
		};

		this.setupEvents();
		render();
	}

	private async initWebGPU() {
		if (!this.canvas) {
			throw new Error("Canvas not found");
		}

		// WebGPU init
		const adapter = await navigator.gpu?.requestAdapter();
		const device = await adapter?.requestDevice();
		if (!device) {
			this.isWebGPUSupported = false;
			throw new Error("WebGPU is not supported on this device");
		}
		const context = this.canvas.getContext("webgpu");
		if (!context) {
			throw new Error("WebGPU not supported");
		}
		const devicePixelRatio = window.devicePixelRatio || 1;
		const presentationSize = [this.canvas.clientWidth * devicePixelRatio, this.canvas.clientHeight * devicePixelRatio];
		this.canvas.width = presentationSize[0];
		this.canvas.height = presentationSize[1];
		const presentationFormat = navigator.gpu.getPreferredCanvasFormat();
		context.configure({
			device,
			format: presentationFormat,
		});

		return { device, context, presentationFormat };
	}

	private createPipeline(
		device: GPUDevice,
		presentationFormat: GPUTextureFormat,
		module: GPUShaderModule,
		bindGroupLayouts: GPUBindGroupLayout[]
	) {
		const pipelineLayout = device.createPipelineLayout({
			bindGroupLayouts,
		});
		const pipeline = device.createRenderPipeline({
			layout: pipelineLayout,
			vertex: {
				module,
				entryPoint: "vertex_shader",
			},
			fragment: {
				module,
				entryPoint: "fragment_shader",
				targets: [{ format: presentationFormat }],
			},
		});
		return pipeline;
	}

	private setupEvents() {
		if (!this.canvas) {
			throw new Error("Canvas not found");
		}

		window.addEventListener("resize", () => {
			if (!this.canvas) {
				throw new Error("Canvas not found");
			}
			const devicePixelRatio = window.devicePixelRatio || 1;
			const presentationSize = [
				this.canvas.clientWidth * devicePixelRatio,
				this.canvas.clientHeight * devicePixelRatio,
			];
			this.canvas.width = presentationSize[0];
			this.canvas.height = presentationSize[1];
			this.aspectRatio = this.canvas.clientWidth / this.canvas.clientHeight;
		});

		let lastX: number | null = null;
		let lastY: number | null = null;

		const handlePointerDown = (event: PointerEvent) => {
			this.isMouseDown = 1;
			lastX = event.clientX;
			lastY = event.clientY;
			this.canvas?.setPointerCapture(event.pointerId);
		};

		const handlePointerUp = () => {
			this.isMouseDown = 0;
			lastX = null;
			lastY = null;
		};

		const handlePointerMove = (event: PointerEvent) => {
			if (this.isMouseDown !== 1) return;

			const dx = lastX !== null ? event.clientX - lastX : 0;
			const dy = lastY !== null ? event.clientY - lastY : 0;

			this.azimuth += dx * 0.005;
			this.polar -= dy * 0.005;
			this.polar = Math.max(0.1, Math.min(Math.PI - 0.1, this.polar));
			this.cameraPosition = this.updateCameraPos();

			lastX = event.clientX;
			lastY = event.clientY;
		};

		this.canvas.addEventListener("pointerdown", handlePointerDown, { passive: true });
		this.canvas.addEventListener("pointerup", handlePointerUp, { passive: true });
		this.canvas.addEventListener("pointermove", handlePointerMove, { passive: true });

		this.canvas.addEventListener(
			"wheel",
			(event: WheelEvent) => {
				this.distanceToScene += event.deltaY * 0.002;
				this.distanceToScene = Math.max(0.1, this.distanceToScene);
				this.cameraPosition = this.updateCameraPos();
			},
			{ passive: true }
		);

		this.canvas.style.touchAction = "none";
	}
	
	private updateCameraPos(): [number, number, number, number] {
		const radius = this.distanceToScene;
		const x = radius * Math.sin(this.polar) * Math.cos(this.azimuth);
		const y = radius * Math.cos(this.polar);
		const z = radius * Math.sin(this.polar) * Math.sin(this.azimuth);
		return [x, y, z, 0];
	}
}

export const scene = new Scene();
