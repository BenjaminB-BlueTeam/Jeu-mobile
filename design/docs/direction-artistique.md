# Direction artistique — Iron Front
**Version 1.0 — 23/07/2026 — Ben**
Référence visuelle maîtresse : `design/da/reference-01.png` (à copier depuis le pin Pinterest source).

## 1. Pilier
**"Painted top-down ¾, militaire chaud, léger et lisible."**
Rendu peint cartoon à texture granuleuse (façon pixel-painted HD), ton Advance Wars : la guerre est crédible mais jamais sombre ni gore.

## 2. Rendu
- Style : peint numérique "chunky", volumes simplifiés et arrondis, texture granuleuse subtile (pas de pixel art strict, pas de vectoriel flat).
- Contours : trait doux, couleur = teinte locale assombrie (~-40% luminosité), jamais noir pur, épaisseur variable.
- Lumière : diffuse, source haut-gauche, ombres portées douces (teinte du sol assombrie, opacité ~35%, décalées bas-droite).
- Pas de rendu réaliste, pas de photobashing, pas de dégradés lisses type vectoriel.

## 3. Perspective
- Top-down ¾ : caméra plongeante ~60-70°. On voit le toit + la façade avant des bâtiments.
- Grille carrée. Aucun asset isométrique (losanges interdits).
- Les unités/véhicules : vues de ¾ dessus, orientation 4 directions (N/S/E/O) minimum.

## 4. Palette globale (semi-désaturée militaire chaude)
Sols et environnement :
- Herbe/plaine : olive désaturé #7A8450, variations #6B7544 / #8A9460
- Terre/chemins : brun chaud #8C6B4F, usure #A58164
- Toundra : beige froid #B0A88E ; Désert : sable chaud #C7A876
- Eau : turquoise désaturé #5E9490
- Roche/béton : gris chaud #8E8578
Bâtiments :
- Structures : béton chaud #9C9284, métal #6E6A61, bois #7D5F45, rouille #9C5B3C
- Toits : kaki #6F6E4E ou métal sombre #55524A
Accents (à doser, ~10% de la surface) :
- Alerte/feu : orange brûlé #C96F3B
- Énergie : jaune chaud #D9A93F
- Couleurs faction (voir §6)
Règle : saturation moyenne 25-45%, jamais de couleur pure saturée hors VFX et accents faction.

## 5. Sol et environnement
- Tiles de sol avec variations (3-4 par biome) + décals de détail : touffes d'herbe, cailloux, fleurs pâles, traces de chenilles, impacts, débris.
- Chemins usés organiques (bords irréguliers) reliant les bâtiments, comme la référence.
- Végétation : arbres boules chunky, buissons ronds, épaves végétalisées.

## 6. Factions (accents cosmétiques uniquement)
Appliqués sur drapeaux, marquages véhicules, toiles, lumières — jamais sur les structures entières :
- Ashen Legion : rouge brique #A6413A + noir chaud #3A3532
- Azure Pact : bleu acier #4A7291 + blanc cassé #D9D4C7
- Verdant Union : vert forêt #55703F + brun #6B5138
- Golden Syndicate : or terni #B8923F + gris chaud #7A756B

## 7. Spécifications techniques assets
- Grille logique : 1 tile = 128 px (base), export @2x (256 px) pour retina.
- Bâtiments : footprint 2x2 tiles standard (512 px @2x), HQ 3x3, tourelles/défenses 1x1. Hauteur visuelle libre (peut déborder vers le haut, jamais sur les côtés/bas).
- Unités : canvas 1x1 tile, le véhicule occupe ~70% du canvas.
- Fond transparent, PNG. Ombre portée intégrée à l'asset.
- Godot : import filter ON (Linear), pas de snap pixel.
- 3 états par bâtiment à terme : construction (échafaudages bois + bâches), normal, endommagé (fumée, impacts). V1 : état normal seul.

## 8. VFX et animation (direction)
- Explosions "pop" satisfaisantes : boule orange #C96F3B → fumée grise, 4-6 frames, cartoon.
- Fumées de cheminées/usines en boucles douces.
- Jamais de sang, jamais de corps.

## 9. UI (direction sommaire, à détailler plus tard)
- Panneaux : métal chaud #55524A + rivets, coins arrondis légers, façon dépêche militaire.
- Typo : sans-serif condensée bold pour titres, lisible petite taille.
- Icônes ressources : Steel gris-bleu, Components jaune #D9A93F, Fuel orange #C96F3B, Power jaune vif, Gold Ingots or #B8923F.

## 10. Prompt template génération IA (cohérence)
Préfixe de style obligatoire pour tout asset généré :
"top-down 3/4 view game asset, hand-painted cartoon style with subtle grainy pixel-painted texture, chunky rounded shapes, soft dark outlines (darkened local color, never pure black), soft diffuse lighting from top-left, soft drop shadow bottom-right, warm desaturated military palette (olive green #7A8450 ground, warm concrete #9C9284, rust #9C5B3C, warm metal #6E6A61), Advance Wars tone, no gore, transparent background, single asset centered"
+ description de l'asset + "consistent with reference sheet".
Toujours générer en batch avec la référence maîtresse en image de référence quand l'outil le permet (Higgsfield/GPT-Image).

## 11. Interdits
- Pixel art basse résolution (les tiles Kenney 16px actuels = placeholders à remplacer).
- Isométrique, vectoriel flat, réalisme photo, dark/grimdark.
- Couleurs saturées pures hors VFX/accents.
- Gore, références militaires réelles (insignes, drapeaux, modèles de véhicules existants reconnaissables).
