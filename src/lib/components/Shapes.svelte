<script lang="ts">
	// Models
	import { scene } from "$lib/models/Scene.svelte";

	// Variables
	const shapes = [
		{
			id: 0,
			name: "Sphere",
		},
		{
			id: 1,
			name: "Torus",
		},
		{
			id: 2,
			name: "Box",
		},
		{
			id: 3,
			name: "Box Frame",
		},
		{
			id: 4,
			name: "Gyroid",
		},
	];
</script>

<!-- Main container -->
<div class="flex flex-col justify-between items-center gap-4 w-full">
	<div class="flex flex-row justify-between items-center w-full">
		<p class="text-gray-400">Shape 1</p>
		<select
			bind:value={scene.shape1}
			class="w-44 p-1 rounded bg-dark-gray border border-light-gray focus:outline-none"
		>
			{#each shapes as shape}
				<option value={shape.id}>{shape.name}</option>
			{/each}
		</select>
	</div>
	<div class="flex flex-row justify-between items-center gap-4 w-full">
		<p class="text-gray-400">Shape 2</p>
		<select
			bind:value={scene.shape2}
			class="w-44 p-1 rounded bg-dark-gray border border-light-gray focus:outline-none"
		>
			{#each shapes as shape}
				<option value={shape.id}>{shape.name}</option>
			{/each}
		</select>
	</div>
</div>
