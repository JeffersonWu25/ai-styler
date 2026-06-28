from dataclasses import dataclass
from pathlib import Path

from app.config import ASSETS_DIR

TRY_ON_PROMPT = """\
Image 1: full-body front photo of the person.
Images 2 onward: clothing reference photos for the outfit.

Edit Image 1 to dress the person using the provided clothing images. \
Do not change their face, facial features, skin tone, body shape, pose, or identity in any way. \
Preserve their exact likeness, expression, hairstyle, and proportions. \
Replace only the clothing, fitting the garments naturally to their existing pose and body geometry with realistic fabric behavior. \
Match lighting, shadows, and color temperature to the original photo so the outfit integrates photorealistically, without looking pasted on. \
Do not change the background, camera angle, framing, or image quality, and do not add accessories, text, logos, or watermarks.\
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
        name="Old Money",
        garment_filenames=(
            "pants_front.png",
            "sweater_vneck.png",
            "loafers.png",
        ),
        prompt=TRY_ON_PROMPT,
    ),
}


def get_outfit(outfit_id: str) -> Outfit:
    outfit = OUTFITS.get(outfit_id)
    if outfit is None:
        raise KeyError(f"Unknown outfit: {outfit_id}")
    return outfit
