<script lang="ts">
	// Models
	import { scene } from "$lib/models/Scene.svelte";
</script>

<!-- Main container -->
<div class="flex flex-row justify-between items-center w-full">
	<p class="text-gray-400">Time</p>
	<div class="flex flex-row justify-center items-center max-w-44 w-full space-x-2">
		<img src="/icons/tortoise.svg" alt="tortoise" class="w-6 h-6" />
		<input
			id="labels-range-input"
			type="range"
			bind:value={scene.speed}
			min="0.0"
			max="1.0"
			step="0.01"
			class="styled-range w-full h-2 rounded-sm bg-extra-light-gray appearance-none cursor-pointer"
		/>
		<img src="/icons/hare.svg" alt="hare" class="w-5 h-5 mb-1" />
	</div>
</div>


