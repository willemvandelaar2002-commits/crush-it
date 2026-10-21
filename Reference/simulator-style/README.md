# Crush It — video art references

Extracted on 2026-10-21 from the two recordings supplied by the project owner.

This folder contains **49 full-size screenshots, 12 detail crops and 4 contact sheets**. Full screenshots keep the source resolution (industrial: 1910 × 1004; capybara: 1918 × 1034). The images are JPEGs to keep the GitHub folder practical. Crops contain actual footage pixels: no AI regeneration, retouching or enlargement. The original videos are not included.

## Start here

Browse the [industrial contact sheets](contact-sheets/industrial-overview-01.jpg) and [capybara contact sheets](contact-sheets/capybara-overview-01.jpg), then open the full-size images and the `details/` folder. Contact sheets are previews; use individual images to inspect studs, borders and materials.

Suggested repository location: `docs/references/simulator-style/`. Copy this folder's contents there. Keep these files outside Rojo's `src/` tree.

These recordings are external visual references, not screenshots of the current Crush It implementation. Labels `industrial` and `capybara` are descriptive; the pack does not assert the games' official titles.

## Direction for Codex

Use the reference images to study world art: strong ground colour blocks, consistent stud scale, simple chunky props, raised platform edges, readable paths, grouped landmarks and layered background scenery. Adapt those principles to **Crush It's cheerful toy scrapyard**: blue-grey workshop plots, tan surroundings, green cliff terraces, colourful containers and yellow industrial accents.

The owner explicitly wants **world changes**. Preserve existing presses and their upgrade progression, UI, gameplay, economy, plot footprints, interaction positions and navigation. Do not use the reference vaults, tanks, capybaras or shop systems as requests to replace Crush It's mechanics or assets. Read `CLAUDE.md` and `docs/Home.md` and follow the repository's current edit restrictions before implementing anything.

The capybara recording is especially useful for daylight colour, cliffs, planted edges and orderly repeated plots. The industrial recording is useful for ground contrast, station grouping, signs and large landmarks. Its latter half is a night event: use those frames for shapes and layout, not as the target lighting. Full frames retain the recorded HUD and tutorial overlays. Two early industrial screenshots show UI panels as supplementary references; the purchase dialog and several repetitive shots were omitted.

These frames illustrate a visual style. They do not establish which texture assets either reference game uses, or prove that the newly imported stud material pack matches those games.

## Best starting images for the world

- [Industrial daytime overview](industrial/industrial-05s-daytime-market-overview.jpg): dark working floor against warm ground.
- [Industrial station composition](industrial/industrial-15s-open-work-floor-and-stations.jpg): open routes framed by stations.
- [Industrial tree and sign landmark](industrial/industrial-17s-upgrade-signs-and-tree-landmark.jpg): grouped background elements.
- [Capybara plot grid and cliffs](capybara/capybara-03s-plot-grid-and-cliff-overview.jpg): repeated plots and green-topped borders.
- [Capybara waterfall and canals](capybara/capybara-11s-waterfall-canals-and-market-stall.jpg): large landmark and contrasting routes.
- [Capybara trees and landscape](capybara/capybara-17s-grassy-route-and-pink-tree.jpg): bright foliage and stepped cliffs.
- [Capybara surface details](details/capybara-37s-detail-pool-studs-bridges-and-borders.jpg): stud spacing, bridges and borders.

## Contact sheets

- [Industrial, page 1](contact-sheets/industrial-overview-01.jpg)
- [Industrial, page 2](contact-sheets/industrial-overview-02.jpg)
- [Capybara, page 1](contact-sheets/capybara-overview-01.jpg)
- [Capybara, page 2](contact-sheets/capybara-overview-02.jpg)

## Full screenshot index

Times refer to the supplied recordings. `index.csv` provides a machine-readable index; `manifest.json` includes crop rectangles and dimensions.

| Image | Time | What to study |
| --- | --- | --- |
| [industrial-01s-offline-earnings-panel](industrial/industrial-01s-offline-earnings-panel.jpg) | 00:01 | UI: two reward choices, warm panel header and outlined text. |
| [industrial-03s-daily-rewards-panel](industrial/industrial-03s-daily-rewards-panel.jpg) | 00:03 | UI: coloured reward cells, thick panel border and icon sizing. |
| [industrial-05s-daytime-market-overview](industrial/industrial-05s-daytime-market-overview.jpg) | 00:05 | World: charcoal work area against golden ground; clustered signs and large landmarks. |
| [industrial-07s-work-platforms-and-gold-landmark](industrial/industrial-07s-work-platforms-and-gold-landmark.jpg) | 00:07 | World: platform outlines, ground colour contrast and oversized landmark. |
| [industrial-09s-gold-landmark-close-view](industrial/industrial-09s-gold-landmark-close-view.jpg) | 00:09 | World: exaggerated landmark scale, simple stepped shapes and a low raised base. |
| [industrial-11s-smelter-and-gold-landmark](industrial/industrial-11s-smelter-and-gold-landmark.jpg) | 00:11 | World: dark smelter, warm glow and gold landmark composition. |
| [industrial-13s-portal-smelter-and-sign-cluster](industrial/industrial-13s-portal-smelter-and-sign-cluster.jpg) | 00:13 | World: a tall portal landmark behind lower functional stations. |
| [industrial-15s-open-work-floor-and-stations](industrial/industrial-15s-open-work-floor-and-stations.jpg) | 00:15 | World: clear walking space framed by equipment and freestanding signs. |
| [industrial-17s-upgrade-signs-and-tree-landmark](industrial/industrial-17s-upgrade-signs-and-tree-landmark.jpg) | 00:17 | World: sign hierarchy, a large tree and grouped station props. |
| [industrial-19s-vault-presentation-and-ground](industrial/industrial-19s-vault-presentation-and-ground.jpg) | 00:19 | Supplementary: isolated chunky object presentation and simple studded ground; do not redesign Crush It presses from this. |
| [industrial-21s-daytime-signs-and-gold-stacks](industrial/industrial-21s-daytime-signs-and-gold-stacks.jpg) | 00:21 | World: bright upright signs supported by a dark floor and gold surroundings. |
| [industrial-25s-upgrade-board-composition](industrial/industrial-25s-upgrade-board-composition.jpg) | 00:25 | World/UI: two upgrade boards with readable colour bands and thick frames. |
| [industrial-29s-daytime-floor-and-landmark-spacing](industrial/industrial-29s-daytime-floor-and-landmark-spacing.jpg) | 00:29 | World: walking clearance around large gold shapes and signs. |
| [industrial-33s-daytime-station-grouping](industrial/industrial-33s-daytime-station-grouping.jpg) | 00:33 | World: grouped stations surrounding an open floor. |
| [industrial-35s-night-event-transition](industrial/industrial-35s-night-event-transition.jpg) | 00:35 | Supplementary night reference: warm practical lights and event signage. Daytime is our target. |
| [industrial-37s-night-work-lanes-and-markings](industrial/industrial-37s-night-work-lanes-and-markings.jpg) | 00:37 | World: dark work lanes with clean white bay outlines. |
| [industrial-39s-night-lane-and-object-card](industrial/industrial-39s-night-lane-and-object-card.jpg) | 00:39 | World/UI: lane borders, equipment placement and nearby object information. |
| [industrial-43s-night-equipment-bay-close-view](industrial/industrial-43s-night-equipment-bay-close-view.jpg) | 00:43 | World: raised base edges and white bay markings; supplementary night lighting. |
| [industrial-45s-night-platform-overview](industrial/industrial-45s-night-platform-overview.jpg) | 00:45 | World: layout and scale relationships between work platforms and stations. |
| [industrial-47s-boost-shop-building-and-props](industrial/industrial-47s-boost-shop-building-and-props.jpg) | 00:47 | World: striped awning, chunky booth construction, fence and surrounding props. |
| [industrial-49s-perimeter-fence-and-event-landmarks](industrial/industrial-49s-perimeter-fence-and-event-landmarks.jpg) | 00:49 | World: large background silhouettes, a low fence and scattered ground patches. |
| [industrial-51s-night-station-signs](industrial/industrial-51s-night-station-signs.jpg) | 00:51 | World: freestanding signs grouped around a functional station. |
| [industrial-55s-event-area-and-water-edge](industrial/industrial-55s-event-area-and-water-edge.jpg) | 00:55 | World: boundary fencing, water edge and grouped background silhouettes. |
| [industrial-57s-perimeter-water-and-feedback-booth](industrial/industrial-57s-perimeter-water-and-feedback-booth.jpg) | 00:57 | World: layered terrain, water, fencing, booth and sparse ground detail. |
| [industrial-59s-large-tree-and-fenced-water](industrial/industrial-59s-large-tree-and-fenced-water.jpg) | 00:59 | World: large tree silhouette, water edge and boundary depth. |
| [capybara-03s-plot-grid-and-cliff-overview](capybara/capybara-03s-plot-grid-and-cliff-overview.jpg) | 00:03 | World: strong grass/water/stone colour blocks, plot repetition and green cliff terraces. |
| [capybara-05s-shop-tank-and-path-arrows](capybara/capybara-05s-shop-tank-and-path-arrows.jpg) | 00:05 | World: a grouped shop/tank scene, coloured pads and large ground arrows. |
| [capybara-07s-striped-awning-stall-and-trees](capybara/capybara-07s-striped-awning-stall-and-trees.jpg) | 00:07 | World: friendly market stall, gateway, pink trees and warm stone borders. |
| [capybara-09s-gateway-and-wooden-bridge](capybara/capybara-09s-gateway-and-wooden-bridge.jpg) | 00:09 | World: large gateway pillars and a contrasting bridge route through water. |
| [capybara-11s-waterfall-canals-and-market-stall](capybara/capybara-11s-waterfall-canals-and-market-stall.jpg) | 00:11 | World: waterfall landmark, canal edges, bridge and small shop composition. |
| [capybara-13s-raised-shop-platform-and-water](capybara/capybara-13s-raised-shop-platform-and-water.jpg) | 00:13 | World: raised foundation, stone edging, arrows and canal layout. |
| [capybara-15s-tank-stall-and-canal-composition](capybara/capybara-15s-tank-stall-and-canal-composition.jpg) | 00:15 | World: large cylinder landmark, smaller stall and a clear canal route. |
| [capybara-17s-grassy-route-and-pink-tree](capybara/capybara-17s-grassy-route-and-pink-tree.jpg) | 00:17 | World: open grass, contrasting water, grouped trees and stepped cliffs. |
| [capybara-19s-bridge-and-blue-banner-gateway](capybara/capybara-19s-bridge-and-blue-banner-gateway.jpg) | 00:19 | World: layered gateway shapes, bridge studs and waterside lanterns. |
| [capybara-21s-return-view-to-production-plots](capybara/capybara-21s-return-view-to-production-plots.jpg) | 00:21 | World: clear approach to repeated plots and perimeter sign placement. |
| [capybara-25s-tank-market-and-merge-pad](capybara/capybara-25s-tank-market-and-merge-pad.jpg) | 00:25 | World: landmark scale beside a low interaction pad and small shop. |
| [capybara-27s-market-stall-close-view](capybara/capybara-27s-market-stall-close-view.jpg) | 00:27 | World/UI: awning colours, stall frame, nearby props and reward effects. |
| [capybara-31s-purchase-pads-and-sign-cluster](capybara/capybara-31s-purchase-pads-and-sign-cluster.jpg) | 00:31 | World: coloured purchase pads placed in front of a repeated production grid. |
| [capybara-33s-production-pools-and-stone-borders](capybara/capybara-33s-production-pools-and-stone-borders.jpg) | 00:33 | World: repeated stone-edged pools, small bridges and consistent surface scale. |
| [capybara-37s-pool-divider-and-stud-close-view](capybara/capybara-37s-pool-divider-and-stud-close-view.jpg) | 00:37 | World: stud scale, raised stone borders and small wooden bridge details. |
| [capybara-39s-tank-shop-and-selling-board](capybara/capybara-39s-tank-shop-and-selling-board.jpg) | 00:39 | World: several complementary landmarks sharing one bright environment palette. |
| [capybara-41s-wide-grass-and-production-grid](capybara/capybara-41s-wide-grass-and-production-grid.jpg) | 00:41 | World: open usable foreground with dense but ordered activity behind it. |
| [capybara-43s-production-grid-and-bamboo-edge](capybara/capybara-43s-production-grid-and-bamboo-edge.jpg) | 00:43 | World: bamboo, stone borders and repeating water channels. |
| [capybara-45s-merge-pad-and-station-spacing](capybara/capybara-45s-merge-pad-and-station-spacing.jpg) | 00:45 | World: spacing between coloured pads, canals and large landmarks. |
| [capybara-47s-upgrade-station-and-tank](capybara/capybara-47s-upgrade-station-and-tank.jpg) | 00:47 | World/UI: a large station sign with nearby purchase pads and tank silhouette. |
| [capybara-49s-selling-board-and-lantern](capybara/capybara-49s-selling-board-and-lantern.jpg) | 00:49 | World: chunky sign construction, a warm lantern and planting at its base. |
| [capybara-51s-sign-lantern-and-character-display](capybara/capybara-51s-sign-lantern-and-character-display.jpg) | 00:51 | World: layered sign frame, decorative base and nearby pedestal/display. |
| [capybara-53s-central-route-and-plot-sightline](capybara/capybara-53s-central-route-and-plot-sightline.jpg) | 00:53 | World: long sightline across plots with gateways, trees and perimeter cliffs. |
| [capybara-55s-market-gateway-and-cliff-skyline](capybara/capybara-55s-market-gateway-and-cliff-skyline.jpg) | 00:55 | World: stall, gate, pink foliage and varied cliff heights in one readable scene. |

## Detail crops

| Image | Time | What to study |
| --- | --- | --- |
| [industrial-05s-detail-daytime-floor-colour-and-studs](details/industrial-05s-detail-daytime-floor-colour-and-studs.jpg) | 00:05 | Charcoal stud floor contrasted with golden ground. |
| [industrial-11s-detail-smelter-and-landmark-materials](details/industrial-11s-detail-smelter-and-landmark-materials.jpg) | 00:11 | Dark smelter silhouette, warm glow and chunky gold blocks. |
| [industrial-13s-detail-portal-and-station-scale](details/industrial-13s-detail-portal-and-station-scale.jpg) | 00:13 | Tall portal behind lower stations; relative landmark scale. |
| [industrial-17s-detail-tree-signs-and-ground-grouping](details/industrial-17s-detail-tree-signs-and-ground-grouping.jpg) | 00:17 | Large tree and layered sign/station cluster. |
| [industrial-47s-detail-striped-shop-booth](details/industrial-47s-detail-striped-shop-booth.jpg) | 00:47 | Striped awning and simple shop construction; night reference. |
| [industrial-57s-detail-water-fence-and-perimeter](details/industrial-57s-detail-water-fence-and-perimeter.jpg) | 00:57 | Water boundary, dark fence, terrain and small booth; night reference. |
| [capybara-07s-detail-market-awning-gateway-and-trees](details/capybara-07s-detail-market-awning-gateway-and-trees.jpg) | 00:07 | Chunky market architecture and grouped pink trees. |
| [capybara-11s-detail-waterfall-and-canal-layout](details/capybara-11s-detail-waterfall-and-canal-layout.jpg) | 00:11 | Waterfall landmark, bridges, canals and clear colour separation. |
| [capybara-15s-detail-tank-and-market-group](details/capybara-15s-detail-tank-and-market-group.jpg) | 00:15 | Large orange tank beside a smaller stall and stone-edged route. |
| [capybara-17s-detail-cliffs-grass-and-pink-tree](details/capybara-17s-detail-cliffs-grass-and-pink-tree.jpg) | 00:17 | Green cliff ledges, pink foliage and broad grassy routes. |
| [capybara-37s-detail-pool-studs-bridges-and-borders](details/capybara-37s-detail-pool-studs-bridges-and-borders.jpg) | 00:37 | Stud scale and repeating pools with contrasting stone and wood. |
| [capybara-51s-detail-chunky-sign-lantern-and-display](details/capybara-51s-detail-chunky-sign-lantern-and-display.jpg) | 00:51 | Sign border construction, small warm light and a nearby display. |
