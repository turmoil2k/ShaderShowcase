Shader "Unlit/Eclipse97"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Bgc("Background Color", color) = (0.39,0,0,1)
        _Ec("Eclipse Color", color) = (0,0,0,1)
        _Ec2("Eclipse Ring Color 2", color) = (1,0.5,0.5,1)


        _p1("Property1", float) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define PIE 3.14159

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float4 _Bgc;
            float _p1;
            float4 _Ec;
            float4 _Ec2;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                
                float4 euv = float4(i.uv.xy,0,1);

                float2 cl = length(i.uv.xy * 2 - 1);
                
                float luv = smoothstep(0.45,0.5,cl);
                float luv2 = smoothstep(0.5,0.7,cl);
                
                float4 fc = (1 - luv) * _Ec;
                float4 fc2 = _Ec2 + luv2;

                float4 all = _Bgc + fc;
                
                return all;
                /*
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
                */
            }
            ENDCG
        }
    }
}
