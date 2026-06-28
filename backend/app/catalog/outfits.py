from dataclasses import dataclass
from pathlib import Path

from app.config import ASSETS_DIR

TRY_ON_PROMPT = """\
Image 1: full-body front reference photo of the person.
Image 2: full-body side reference photo of the person.
Image 3: full-body back reference photo of the person.
Image 4: pants reference photo.
Image 5: jacket reference photo.
Image 6: shoes reference photo.

Create a single photorealistic studio fashion try-on composite image.

Layout: three equal full-body panels arranged left to right on one canvas — \
panel 1 = front view, panel 2 = side view, panel 3 = back view. \
Plain white seamless studio background across all panels. \
Soft, even studio lighting with natural shadows and correct perspective.

For each panel, dress the same person in the complete outfit from the garment \
reference images. Match each panel's body pose, stance, and camera angle to \
the corresponding person reference (front panel → Image 1, side panel → Image 2, \
back panel → Image 3).

Preserve the same identity across all three panels: exact face, facial features, \
skin tone, hair, body proportions, and height. Do not beautify the face, slim \
or reshape the body, or change height.

Garments: accurate structure, fit, fabric texture, color, seams, and proportions. \
Realistic draping, folds, and occlusion. The outfit should look naturally worn, \
not pasted on.

Do not add text, logos, watermarks, borders between panels, or extra accessories. \
Do not make the result look AI-generated, over-smoothed, or plastic.\
"""


@dataclass(frozen=True)
class Outfit:
    id: str
    name: str
    garment_filenames: tuple[str, ...]
    prompt: str

    @property
    def assets_dir(self) -> Path:
        return ASSETS_DIR / "outfits" / self.id

    def garment_paths(self) -> list[Path]:
        paths = [self.assets_dir / filename for filename in self.garment_filenames]
        missing = [path for path in paths if not path.is_file()]
        if missing:
            names = ", ".join(path.name for path in missing)
            raise FileNotFoundError(
                f"Missing garment assets for outfit '{self.name}': {names}. "
                f"Add PNG files to {self.assets_dir}"
            )
        return paths


OUTFITS: dict[str, Outfit] = {
    "old-money": Outfit(
        id="old-money",
        name="Streetwear",
        garment_filenames=(
            "shein-jeans.png",
            "stussy-jacket.png",
            "new-balance-shoes.png",
        ),
        prompt=TRY_ON_PROMPT,
    ),
}


def get_outfit(outfit_id: str) -> Outfit:
    outfit = OUTFITS.get(outfit_id)
    if outfit is None:
        raise KeyError(f"Unknown outfit: {outfit_id}")
    return outfit
