# AI Styler

AI Styler is a virtual try-on app. You upload three photos of yourself — front, side, and back — and the app shows you what you'd look like wearing a specific outfit.

For the MVP, the outfit is hardcoded on the backend. When you tap try-on, the app sends your photos to a Python server, which calls OpenAI's GPT Image 2 to generate a photorealistic image of you in that outfit. The goal is natural fit and likeness: same face, same body, new clothes.

The iOS app handles photo capture and displaying results. The backend holds the API key, outfit definitions, garment reference images, and prompts — so we can change outfits and tune quality without shipping a new app version.
