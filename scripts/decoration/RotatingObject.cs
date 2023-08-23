using Godot;
using System;

public partial class RotatingObject : StaticBody3D
{
	public override void _Process(double delta)
	{
		RotateY(Mathf.DegToRad(10 * (float)delta));
	}
}
