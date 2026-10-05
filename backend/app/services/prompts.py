from app.models import ClothingCategory, ClothingItem

PERSON_IMAGE_LINES = (
    "Image 1: full-body front reference photo of the person.",
    "Image 2: full-body side reference photo of the person.",
    "Image 3: full-body back reference photo of the person.",
)

CATEGORY_LABELS = {
    ClothingCategory.SHIRT: "top",
    ClothingCategory.BOTTOM: "pants",
    ClothingCategory.OUTERWEAR: "jacket",
    ClothingCategory.SHOE: "shoes",
}

TRY_ON_INSTRUCTIONS = """\
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


def build_try_on_prompt(items: list[ClothingItem]) -> str:
    """Items must be in the same order their images are sent, after the 3 person photos."""
    garment_lines = [
        f"Image {index}: {CATEGORY_LABELS[item.category]} reference photo "
        f"({item.brand} {item.name})."
        for index, item in enumerate(items, start=len(PERSON_IMAGE_LINES) + 1)
    ]
    header = "\n".join([*PERSON_IMAGE_LINES, *garment_lines])
    return f"{header}\n\n{TRY_ON_INSTRUCTIONS}"
