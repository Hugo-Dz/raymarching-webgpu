<script lang="ts">
	// Models
	import { scene } from "$lib/models/Scene.svelte";

	// Variables
	const operations = [
		{
			id: 0,
			name: "Union",
		},
		{
			id: 1,
			name: "Intersect",
		},
		{
			id: 2,
			name: "Subtract",
		},
	];
</script>

<!-- Main container -->
<div class="flex flex-col justify-between items-center gap-4 w-full">
	<div class="flex flex-row justify-between items-center w-full">
		<p class="text-gray-400">Operation</p>
		<select
			bind:value={scene.operation}
			class="w-44 p-1 rounded bg-dark-gray border border-light-gray focus:outline-none"
		>
			{#each operations as operation}
				<option value={operation.id}>{operation.name}</option>
			{/each}
		</select>
	</div>
</div>
