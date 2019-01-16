// (Infinite) Plane
// n.xyz: normal of the plane
// n.w: offset
float sdPlane(float3 p, float4 n) {
	// n must be normalized
	return dot(p, n.xyz) + n.w;
}

// Sphere
// s: radius
float sdSphere(float3 p, float s)
{
	return length(p) - s;
}

// Box
// b: size of box in x/y/z
float sdBox(float3 p, float3 b)
{
	float3 d = abs(p) - b;
	return min(max(d.x, max(d.y, d.z)), 0.0) +
		length(max(d, 0.0));
}

// Rounded box
float sdRoundBox(in float3 p, float3 b, in float r) {
	float3 q = abs(p) - b;
	return min(max(q.x, max(q.y, q.z)), 0.0) + length(max(q, 0.0)) - r;
}

// SMOOTH BOOLEAN OPERATORS

float opUS(float d1, float d2, float k) {
	float h = clamp(0.5 + 0.5 * (d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) - k * h*(1.0 - h);
}

float opSS(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5*(d2 + d1) / k, 0.0, 1.0);
	return lerp(d2, -d1, h) + k * h*(1.0 - h);
}

float opIS(float d1, float d2, float k) {
	float h = clamp(0.5 - 0.5*(d2 - d1) / k, 0.0, 1.0);
	return lerp(d2, d1, h) + k * h*(1.0 - h);
}

// BOOLEAN OPERATORS //

// Union
float opU(float d1, float d2)
{
	return min(d1, d2);
}

// Subtraction
float opS(float d1, float d2)
{
	return max(-d1, d2);
}

// Intersection
float opI(float d1, float d2)
{
	return max(d1, d2);
}

// Mod Position Axis
float pMod1 (inout float p, float size)
{
	float halfsize = size * 0.5;
	float c = floor((p+halfsize)/size);
	p = fmod(p+halfsize,size)-halfsize;
	p = fmod(-p+halfsize,size)-halfsize;
	return c;
}

float DE(float3 z, float Scale, int Iterations, float offset)
{
	float r;
	int n = 0;
	while (n < Iterations) {
		if (z.x + z.y < 0) z.xy = -z.yx; // fold 1
		if (z.x + z.z < 0) z.xz = -z.zx; // fold 2
		if (z.y + z.z < 0) z.zy = -z.yz; // fold 3	
		z = z * Scale - offset * (Scale - 1.0);
		n++;
	}
	return (length(z)) * pow(Scale, -float(n));
}

float DEM(float3 pos, int Iterations, float Bailout, float Power) {
	float3 z = pos;
	float dr = 1.0;
	float r = 0.0;
	for (int i = 0; i < Iterations; i++) {
		r = length(z);
		if (r > Bailout) break;

		// convert to polar coordinates
		float theta = acos(z.z / r);
		float phi = atan2(z.y, z.x);
		dr = pow(r, Power - 1.0)*Power*dr + 1.0;

		// scale and rotate the point
		float zr = pow(r, Power);
		theta = theta * Power;
		phi = phi * Power;

		// convert back to cartesian coordinates
		z = zr * float3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z += pos;
	}
	return 0.5*log(r)*r / dr;
}
