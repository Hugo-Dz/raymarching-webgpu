<script lang="ts">
	// Svelte
	import { onMount } from "svelte";

	// Components
	import Aside from "$lib/components/Aside.svelte";

	// Models
	import { scene } from "$lib/models/Scene.svelte";

	// Variables
	let rootElement: HTMLDivElement;

	onMount(() => {
		scene.init(rootElement);
	});
</script>

<!-- Main container -->
<div
	class="relative h-screen w-screen overflow-hidden flex flex-col sm:flex-row justify-center items-center gap-2 p-2 bg-dark-gray"
>
	{#if scene.isWebGPUSupported}
		<div
			class="h-full rounded-xl overflow-hidden w-full border border-light-gray/50 flex flex-col justify-center items-center"
			bind:this={rootElement}
		></div>
		<Aside />
	{:else}
		<div class="text-white text-lg">WebGPU is not supported on this device</div>
	{/if}
</div>
